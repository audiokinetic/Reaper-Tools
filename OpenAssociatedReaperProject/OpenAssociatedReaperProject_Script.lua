--[[
  @description OpenAssociatedReaperProject_Script
  @author Audiokinetic
  @noindex
  @provides
    [nomain] . https://raw.githubusercontent.com/audiokinetic/Reaper-Tools/$commit/OpenAssociatedReaperProject/OpenAssociatedReaperProject_Script.lua
  @about
    The script opens up the associated REAPER project of a  wav file based on his metadata.
  @license
    Copyright (c) 2023 AUDIOKINETIC Inc.

    The script in this file is licensed to use under the license available at:
    https://raw.githubusercontent.com/audiokinetic/Reaper-Tools/main/License.txt (the "License").
    You may not use this file except in compliance with the License.

    Unless required by applicable law or agreed to in writing, software distributed
    under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
    CONDITIONS OF ANY KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations under the License.
]]--

info = debug.getinfo(1,'S')
scriptPath = info.source:match[[^@?(.*[\/])[^\/]-$]]
local utils = dofile(scriptPath.."Utilities.lua")

local tempProject, _ = reaper.EnumProjects( -1, "" )

local firstTrack = reaper.GetTrack(utils.CURRENT_PROJECT, 0)

if not firstTrack then
  reaper.ShowMessageBox("No audio file sent to REAPER!", "Open Associated REAPER Project: Failed", utils.OK_MESSAGE_BOX)
  return
end

local mediaItemCount = reaper.CountTrackMediaItems(firstTrack)
local mediaItem = reaper.GetTrackMediaItem(firstTrack, 0)
local mediaItemTake = reaper.GetActiveTake(mediaItem)
local pcmSource = reaper.GetMediaItemTake_Source(mediaItemTake)
local filePath = reaper.GetMediaSourceFileName(pcmSource)

if not reaper.file_exists(filePath) then
  reaper.ShowMessageBox("Unable to locate file `" .. filePath .. "`", "Open Associated REAPER Project: Failed", utils.OK_MESSAGE_BOX)
  return
end

-- Read data from wav header --
local pcmSource = reaper.PCM_Source_CreateFromFile(filePath)
local projectName = utils.getMetadata(pcmSource, {"IXML:PROJECT", "IXML:Project", "IXML:project", "INFO:INAME"})
local startOffset = utils.getMetadata(pcmSource, {"Generic:StartOffset"})
local trackName = utils.getMetadata(pcmSource, {"IXML:USER:trackName", "IXML:USER:TRACKNAME", "IXML:USER:TrackName", "IXML:USER:trackname"})

if startOffset == nil then
  startOffset = "0:00.000"
end

if not projectName then
  reaper.ShowMessageBox("IXML:PROJECT header missing or empty in selected file. The script expects the IXML:PROJECT header to contain the associated project name. Make sure 'Embed title/date/time if not provided' and 'Embed start offset' option in the Project Render Metadata are enabled.", "Open Associated REAPER Project: Failed", utils.OK_MESSAGE_BOX)
  return
end

local projectDirectory = utils.getParentDirectory(filePath)

local info = debug.getinfo(1, 'S')
local scriptPath = info.source:match[[^@?(.*[\/])[^\/]-$]]
local reaperProjectsRootPath = scriptPath.."ReaperProjectsRoot.txt"
local file, err = io.open(reaperProjectsRootPath, "r")
local reaperProjectsRoot = os.getenv("REAPERPROJECTSROOT")
if file and not reaperProjectsRoot then
  reaperProjectsRoot = file:read()
  file:close()
end

local function findRppFile(dir, rppFile)
  local i = 0
  local file = reaper.EnumerateFiles(dir, i)
  repeat
    if file ~= nil and file == rppFile then
      return dir .. utils.SEPARATOR_CHAR .. file
    end
    i = i + 1
    file = reaper.EnumerateFiles(dir, i)
  until file == nil

  i = 0
  local subDir = reaper.EnumerateSubdirectories(dir, i)
  repeat
    if subDir ~= nil then
      local ret = findRppFile(dir .. utils.SEPARATOR_CHAR .. subDir, rppFile)
      if ret ~= nil then
        return ret
      end
      i = i + 1
      subDir = reaper.EnumerateSubdirectories(dir, i)
    end
  until subDir == nil
  return nil
end

local projectPath = findRppFile(reaperProjectsRoot, projectName .. ".rpp")

if not projectPath then
  projectName = string.gsub(projectName, "\n", " ")
  reaper.ShowMessageBox("Unable to locate project `" .. projectName .. "` in `" .. reaperProjectsRoot .. "`", "Open Associated REAPER Project: Failed", utils.OK_MESSAGE_BOX)
  return
end

-- Open project and set cursor to start offset --
reaper.Main_OnCommand(41929, 0) -- opens new project tab
reaper.Main_openProject("noprompt:" .. projectPath)

local project, _ = reaper.EnumProjects( -1, "" )

local markersAndRegions, _, _ = reaper.CountProjectMarkers(utils.CURRENT_PROJECT)

local buf = ""
for i = 0, markersAndRegions - 1 do
  local _, isRegion, currentRegionPos, _, currentRegion, index, _ = reaper.EnumProjectMarkers3(0, i)

  if isRegion and reaper.format_timestr(currentRegionPos, buf) == startOffset then
    reaper.GoToRegion(0, index, true)
    reaper.adjustZoom(100, 1, true, -1)
    break
  end
end

local trackView = reaper.JS_Window_FindChildByID(reaper.GetMainHwnd(), utils.TRACK_VIEW_ID)

reaper.Main_OnCommand(40297,0) -- deselect all tracks

if trackName then
  for i = 0, reaper.CountTracks() - 1 do
    local currentTrack = reaper.GetTrack(utils.CURRENT_PROJECT, i)
    local _, currentTrackName = reaper.GetTrackName(currentTrack)

    if currentTrackName == trackName then
      reaper.SetTrackSelected(currentTrack, true)

      -- Get Y postion of track and then scroll to it
      local yPosition = reaper.GetMediaTrackInfo_Value(currentTrack, "I_TCPY")
      reaper.JS_Window_SetScrollPos(trackView, "v", yPosition)
      break
    end
  end
end

reaper.SelectProjectInstance(tempProject)
reaper.Main_OnCommand(40860,0) -- close current project tab
reaper.SelectProjectInstance(project)
