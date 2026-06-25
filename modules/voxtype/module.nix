{
  config,
  lib,
  wlib,
  ...
}:
let
  tomlFmt = config.pkgs.formats.toml { };
  defaultSettings = {
    hotkey = { };
    audio = {
      device = "default";
      sample_rate = 16000;
      max_duration_secs = 60;
    };
    output = {
      mode = "type";
    };
  };
in
{
  _class = "wrapper";
  options = {
    settings = lib.mkOption {
      type = tomlFmt.type;
      default = defaultSettings;
      description = ''
        Configuration of voxtype.
        Default has all minimally required options set.`
      '';
      example =
        let
          pkgs = config.pkgs;
        in
        {
          engine = "parakeet";
          parakeet.model =
            let
              parakeetBaseUrl = "https://huggingface.co/istupakov/parakeet-tdt-0.6b-v3-onnx/resolve/main";
            in
            pkgs.linkFarm "parakeet-tdt-0.6b-v3" [
              {
                name = "encoder-model.onnx";
                path = pkgs.fetchurl {
                  url = "${parakeetBaseUrl}/encoder-model.int8.onnx";
                  hash = "sha256-YTnS+n4bCGCXsnfHFJcl7bq4nMfHrmSyPHQb5AVa/wk=";
                };
              }
              {
                name = "decoder_joint-model.onnx";
                path = pkgs.fetchurl {
                  url = "${parakeetBaseUrl}/decoder_joint-model.int8.onnx";
                  hash = "sha256-7qdIPuPRowN12u3I7YPjlgyRsJiBISeg2Z0ciXdmenA=";
                };
              }
              {
                name = "vocab.txt";
                path = pkgs.fetchurl {
                  url = "${parakeetBaseUrl}/vocab.txt";
                  hash = "sha256-1YVEZ56kvGrFY9H1Ret9R0vWz6Rn8KbiwdwcfTfjw10=";
                };
              }
              {
                name = "config.json";
                path = pkgs.fetchurl {
                  url = "${parakeetBaseUrl}/config.json";
                  hash = "sha256-ZmkDx2uXmMrywhCv1PbNYLCKjb+YAOyNejvA0hSKxGY=";
                };
              }
            ];
          hotkey.enabled = false;
        };
    };
    "voxtype.toml" = lib.mkOption {
      type = wlib.types.file config.pkgs;
      default.path = tomlFmt.generate "voxtype.toml" (defaultSettings // config.settings);
    };
  };
  config.flags = {
    "--config" = config."voxtype.toml".path;
  };
  config.package = config.pkgs.voxtype;
  config.meta.maintainers = [ lib.maintainers.lenny ];
  config.meta.platforms = lib.platforms.linux; # voxtype not packaged on darwin atm
}
