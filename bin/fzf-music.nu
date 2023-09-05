#!/usr/bin/env nu

def main [
  --config: string
  --music-path: string
] {
  let default_config_path = [$env.HOME .fzf-music.config.nuon] | path join
  let config_path = if $config == null { $default_config_path } else { $config }

  let flags = {
    music_path: $music_path
  }

  let config_data = $config_path
  | load-config
  | merge ($flags | generate-config)

  $config_data | play-track
}

def generate-config [] {
  let config = $in
  let default_music_path = [$env.HOME Music] | path join

  {
    music_path: (if $config.music_path == null { $default_music_path } else { $config.music_path })
  }
}

def load-config [] {
  let config_path = $in
  if ($config_path | path exists) { open $config_path } else { {} }
}

def play-track [] {
  let config = $in
  let track_paths = [$config.music_path, '*', '*', '*'] | path join

  ls $track_paths
  | get name
  | to text
  | fzf
  | str trim
  | rhythmbox-client --play-uri $in
}
