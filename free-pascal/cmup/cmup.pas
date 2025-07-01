program Cmup;
{$mode objfpc}

uses SysUtils, StrUtils, Classes;

function GetNestedDirectoreies(const Directory: String): TStringList;
var
  SearchRec: TSearchRec;
  Directories: TStringList;
begin
  Directories := TStringList.Create;
  
  if FindFirst(Directory + '/*', faDirectory, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
      begin
        if (SearchRec.Attr and faDirectory) = faDirectory then
          Directories.Add(SearchRec.Name);
      end;
    until FindNext(SearchRec) <> 0;
    
    FindClose(SearchRec);
  end;
  
  GetNestedDirectoreies := Directories;
end;

function GetFiles(const Directory: String): TStringList;
var
  SearchRec: TSearchRec;
  Files: TStringList;
begin
  Files := TStringList.Create;
  
  if FindFirst(Directory + '/*', faAnyFile, SearchRec) = 0 then
  begin
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
      begin
        if (SearchRec.Attr and faDirectory) <> faDirectory then
          Files.Add(SearchRec.Name);
      end;
    until FindNext(SearchRec) <> 0;
    
    FindClose(SearchRec);
  end;
  
  GetFiles := Files;
end;

function Tree(const Directory: String): TStringList;
var
  Queue: TStringList;
  CurrentDir: String;
  Directories: TStringList;
  i: Integer;
begin
  Tree := TStringList.Create;
  Queue := TStringList.Create;
  try
    Queue.Add(Directory);
    while Queue.Count > 0 do
    begin
      CurrentDir := Queue[0];
      Queue.Delete(0);
      Tree.Add(CurrentDir);
      
      Directories := GetNestedDirectoreies(CurrentDir);
      try
        for i := 0 to Directories.Count - 1 do
          Queue.Add(CurrentDir + '/' + Directories[i]);
      finally
        Directories.Free;
      end;
    end;
  finally
    Queue.Free;
  end;
end;

function CleanDirName(const DirName: String): String;
begin
  CleanDirName := ReplaceStr(DirName, '$', '');
end;

function PathToName(const Path: String): String;
var 
  Parts, RestParts: TStringArray;
  FirstPart, Rest, FirstOfRest: String;
  FirstPartLength: Integer;
begin
  Parts := SplitString(Path, '/');
  FirstPart := Parts[0];
  if Length(Parts) = 1 then
  begin
    PathToName := CleanDirName(FirstPart);
  end
  else
  begin
    FirstPartLength := Length(FirstPart);
    Rest := Copy(Path, FirstPartLength + 2, Length(Path) - FirstPartLength);
    RestParts := SplitString(Rest, '/');
    FirstOfRest := RestParts[0];
    if FirstOfRest[Length(FirstOfRest)] = '$' then
      PathToName := CleanDirName(FirstPart + '-' + PathToName(Rest))
    else
      PathToName := CleanDirName(PathToName(Rest));
  end;
end;

function ConvertToPlaylistName(const DirectoryName: String; const BaseDirectoryLength: Integer): String;
var
  StrippedPath: String;
begin
  StrippedPath := Copy(DirectoryName, BaseDirectoryLength + 2, MaxInt);
  Result := PathToName(StrippedPath);
end;

var
  i, j, BaseDirectoryLength: Integer;
  PathToMusicDirectory, PathToCmusPlaylists, PlaylistName: String;
  Directories, Files, PlaylistLines: TStringList;
begin
  if ParamCount < 2 then
  begin
    WriteLn('Usage: ', ParamStr(0), ' <path_to_music_Directory> <path_to_cmus_playlists>');
    WriteLn('Example: ', ParamStr(0), ' ~/Music ~/.config/cmus/playlists');
    Halt(1);
  end;
  
  PathToMusicDirectory := ParamStr(1);
  PathToCmusPlaylists := ParamStr(2);

  Directories := Tree(PathToMusicDirectory);

  BaseDirectoryLength := Length(PathToMusicDirectory);

  for i := 1 to Directories.Count - 1 do
  begin
    PlaylistName := ConvertToPlaylistName(Directories[i], BaseDirectoryLength);
    Files := GetFiles(Directories[i]);

    if Files.Count = 0 then
      Continue;

    PlaylistLines := TStringList.Create;
    try
      for j := 0 to Files.Count - 1 do
        PlaylistLines.Add(Directories[i] + '/' + Files[j]);
      PlaylistLines.SaveToFile(PathToCmusPlaylists + '/' + PlaylistName);
    finally
      PlaylistLines.Free;
    end;
  end;

  Directories.Free;
end.
