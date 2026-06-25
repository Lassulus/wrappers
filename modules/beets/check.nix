{
  pkgs,
  self,
}:

let
  beetsWrapped =
    (self.wrapperModules.beets.apply {
      inherit pkgs;

      settings = {
        directory = "/tmp/beets-music";
        library = "/tmp/beets-library.db";
        plugins = [
          "musicbrainz"
          "alternatives"
        ];
      };

      extraPlugins.alternatives = pkgs.python3Packages.beets-alternatives;
    }).wrapper;
in
pkgs.runCommand "beets-test" { } ''
  export HOME=$(mktemp -d)

  "${beetsWrapped}/bin/beet" version | grep \
    -e "beets version ${beetsWrapped.version}" \
    -e "plugins: alternatives, musicbrainz"

  touch $out
''
