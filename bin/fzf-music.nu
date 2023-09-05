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
  mut config = {}
  if $flags.music_path != null { $config = ($config | merge { music_path: $flags.music_path }) }
  if $flags.query != null { $config = ($config | merge { query: $flags.query }) }
  $config
}

def load-config [] {
  let config_path = $in

  let config = {
    music_path: ([$env.HOME Music] | path join)
    query: 'track'
  }

  if ($config_path | path exists) { $config | merge (open $config_path) } else { $config }
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
  | sort -n

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
