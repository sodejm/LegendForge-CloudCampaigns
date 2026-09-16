"""Operator CLI. This development release intentionally has no apply command."""
import argparse
from dataclasses import asdict
import json

from .browsers import discover, launch
from .catalog import CatalogAdapter, CatalogError
from .wizard import WizardServer


def main(argv=None):
    parser = argparse.ArgumentParser(prog="legendforge")
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("browsers", help="List installed candidate browsers and versions")
    catalog = commands.add_parser("catalog", help="Read public discovery metadata")
    catalog.add_argument("--system", choices=("cosmere-rpg", "dnd5e"), required=True)
    catalog.add_argument("--publisher", help="Also include this publisher's add-ons")
    wizard = commands.add_parser("wizard", help="Start local selection and credential setup")
    wizard.add_argument("--browser", help="Executable from the discovered browser list")
    args = parser.parse_args(argv)
    if args.command == "browsers":
        print(json.dumps([asdict(b) for b in discover()], indent=2))
        return 0
    if args.command == "catalog":
        try:
            records = CatalogAdapter().search(system=args.system, publisher=args.publisher)
            print(json.dumps([asdict(x) for x in records], indent=2))
            return 0
        except CatalogError as exc:
            parser.exit(1, f"Catalog unavailable: {exc}\n")
    browsers = discover()
    chosen = None
    if args.browser:
        chosen = next((b for b in browsers if b.executable == args.browser), None)
        if chosen is None:
            parser.error("Choose an executable listed by 'legendforge browsers'.")
    with WizardServer() as server:
        print(f"Setup URL: {server.origin}")
        print(f"Pairing code: {server.session.token}")
        print("Paste the pairing code into the wizard. It expires after 15 minutes.")
        if chosen:
            launch(chosen, server.origin)
        else:
            print("Open the URL in an installed supported browser:")
            for browser in browsers:
                print(f"  {browser.family} {browser.version}: {browser.executable}")
        print("Ctrl-C ends the launcher. No cloud provisioning is available in this build.")
        server.timeout = 0.5
        try:
            while not server.session.cancelled and server.session.clock() < server.session.expires:
                server.handle_request()
        except KeyboardInterrupt:
            pass
        finally:
            server.session.cancelled = True
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
