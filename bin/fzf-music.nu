#!/usr/bin/env nu

def main [
  --config: string
  --music-path: string
  --query: string
] {
  let default_config_path = [$env.HOME .fzf-music.config.nuon] | path join
  let config_path = if $config == null { $default_config_path } else { $config }

  let flags = {
    music_path: $music_path
    query: $query
  }

  let config_data = $config_path
  | load-config
  | merge ($flags | generate-config)

  $config_data | play
}

def generate-config [] {
  let flags = $in
  let default_music_path = [$env.HOME Music] | path join
  let default_query = 'track'

  {
    music_path: (if $flags.music_path == null { $default_music_path } else { $flags.music_path })
    query: (if $flags.query == null { $default_query } else { $flags.query })
  }
}

def load-config [] {
  let config_path = $in
  if ($config_path | path exists) { open $config_path } else { {} }
}

def play [] {
  let config = $in

  match $config.query {
    album => { $config | play-album },
    track => { $config | play-track },
    _ => {
      print $"error: ($config.query): invalid query"
      exit 1
    }
  }
}

def play-album [] {
  let config = $in
  let album_paths = [$config.music_path, '*', '*'] | path join

  let track_paths = ls $album_paths
  | where type == dir
  | get name
  | to text
  | fzf
  | str trim
  | ls $in
  | get name

  for -n $path in $track_paths {
    if $path.index == 0 {
      $path.item | rhythmbox-client --play-uri $in
      continue
    }

    $path.item | rhythmbox-client --enqueue $in
  }
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
