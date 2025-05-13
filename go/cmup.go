package main

import (
	"fmt"
	"os"
	"path"
	"path/filepath"
)

type Playlist struct {
	name         string
	content      []string
	subPlaylists []Playlist
}

func (playlist Playlist) Print() {
	fmt.Printf("Playlist: %s (Files: %d, Sub-playlists: %d)\n",
		playlist.name, len(playlist.content), len(playlist.subPlaylists))

	for _, file := range playlist.content {
		fmt.Printf("  - File: %s\n", filepath.Base(file))
	}

	for _, sub := range playlist.subPlaylists {
		fmt.Printf("  - Sub-playlist: %s\n", sub.name)
	}
}

func readPlaylist(dir os.DirEntry, dirPath string) (Playlist, error) {
	if !dir.IsDir() {
		return Playlist{}, fmt.Errorf("cannot read playlist from '%s': not a directory", dir.Name())
	}

	content, err := os.ReadDir(dirPath)

	if err != nil {
		return Playlist{}, fmt.Errorf("failed to read directory '%s': %w", dirPath, err)
	}

	result := make([]string, 0)
	nested := make([]Playlist, 0)

	for _, entry := range content {
		entryPath := path.Join(dirPath, entry.Name())

		if !entry.IsDir() {
			result = append(result, entryPath)
			continue
		}

		subPlaylist, err := readPlaylist(entry, entryPath)

		if err != nil {
			fmt.Printf("Warning: %v\n", err)
			continue
		}

		nested = append(nested, subPlaylist)
	}

	return Playlist{dir.Name(), result, nested}, nil
}

func readMusicPlaylists(homePath string) ([]Playlist, error) {
	musicDir := path.Join(homePath, "Music")
	dir, err := os.ReadDir(musicDir)

	if err != nil {
		return nil, fmt.Errorf("failed to read Music directory: %w", err)
	}

	result := make([]Playlist, 0)

	for _, entry := range dir {
		if !entry.IsDir() {
			continue
		}

		playlistPath := path.Join(musicDir, entry.Name())
		playlist, err := readPlaylist(entry, playlistPath)

		if err != nil {
			fmt.Printf("Warning: %v\n", err)
			continue
		}

		result = append(result, playlist)
	}

	return result, nil
}

func main() {
	home, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("Error getting user home directory: %v\n", err)
		os.Exit(1)
	}

	playlists, err := readMusicPlaylists(home)

	if err != nil {
		fmt.Printf("Error reading music playlists: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Found %d playlists\n", len(playlists))

	for _, playlist := range playlists {
		playlist.Print()
	}
}
