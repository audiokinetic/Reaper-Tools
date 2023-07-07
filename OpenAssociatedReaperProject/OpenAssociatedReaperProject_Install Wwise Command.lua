--[[
  @description OpenAssociatedReaperProject_Install Wwise Command
  @author Audiokinetic
  @noindex
  @provides
    [main=main] . https://raw.githubusercontent.com/audiokinetic/Reaper-Tools/$commit/OpenAssociatedReaperProject/OpenAssociatedReaperProject_Install%20Wwise%20Command.lua
  @about
    The script installs the Wwise command to open the associated REAPER project of a rendered wav file.
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

if not utils.ReaperMinimumVersionCheck() then
  reaper.ShowMessageBox("Installation aborted!", "Open Associated REAPER Project", utils.OK_MESSAGE_BOX)
  return
end

if not utils.JSDependencyCheck() then
  return
end

local introMessage = "This script will install the Open Associated REAPER Project command in Wwise and configure the root lookup directory for the REAPER projects."
local userChoice = reaper.ShowMessageBox(introMessage, "Open Associated REAPER Project", utils.OK_CANCEL_MESSAGE_BOX)
if userChoice == utils.CANCEL_RESULT then
  reaper.ShowMessageBox("Installation aborted!", "Open Associated REAPER Project", utils.OK_MESSAGE_BOX)
  return
end

-- setup Wwise command
wwiseCommand = [[
{
    "version": 2,
    "commands": [
        {
            "id": "ak.open_associated_reaper_project",
            "displayName": "Open Associated REAPER Project",
            "program": "{REAPER_PATH}reaper.exe",
            "args": "${sound:originalWavFilePath} {SCRIPT_PATH}OpenAssociatedReaperProject_Script.lua",
            "cwd": "",
            "contextMenu": {
                "enabledFor": "Sound",
                "visibleFor": "Sound"
            }
        }
    ]
}
]]

if not utils.WindowsOS() then
  wwiseCommand = [[
  {
      "version": 2,
      "commands": [
          {
              "id": "ak.open_associated_reaper_project",
              "displayName": "Open Associated REAPER Project",
              "program": "open",
              "args": "-n {REAPER_PATH}REAPER.app --args ${sound:originalWavFilePath} '{SCRIPT_PATH}OpenAssociatedReaperProject_Script.lua'",
              "cwd": "",
              "contextMenu": {
                  "enabledFor": "Sound",
                  "visibleFor": "Sound"
              }
          }
      ]
  }
  ]]
end

reaperPath = utils.getReaperPath()
appData = utils.getAppData()

wwiseCommand = wwiseCommand:gsub("{REAPER_PATH}", reaperPath)

info = debug.getinfo(1,'S')
scriptPath = info.source:match[[^@?(.*[\/])[^\/]-$]]
if utils.WindowsOS() then
  scriptPath = scriptPath:gsub("\\", "\\\\")
end

wwiseCommand = wwiseCommand:gsub("{SCRIPT_PATH}", scriptPath)

-- Install Wwise command
openInReaperPath = appData.."/Audiokinetic/Wwise/Add-ons/Commands/"
if utils.WindowsOS() then
  openInReaperPath = openInReaperPath:gsub("/", "\\")
end

reaper.RecursiveCreateDirectory(openInReaperPath)
openInReaperPath = openInReaperPath.."OpenAssociatedReaperProject.json"

file, err = io.open(openInReaperPath, "w")
if file then
  file:write(wwiseCommand)
  file:close()
else
    reaper.ShowMessageBox("Failed to write to "..openInReaperPath, "WriteOpenReaper", utils.OK_MESSAGE_BOX)
    return
end

-- setup ReaperProjectsRoot.txt
reaperProjectsRoot = scriptPath.."ReaperProjectsRoot.txt"
retval = ""
file, err = io.open(reaperProjectsRoot, "r")
if file then
  retval = file:read()
  file:close()
end

intval, retval = reaper.JS_Dialog_BrowseForFolder("Select root directory of your REAPER projects.", retval)
if intval == utils.OK_RESULT and retval then
  file, err = io.open(reaperProjectsRoot, "w")
  if file then
    file:write(retval)
    file:close()
  end
end

local importantNote = "Important Note:\nOpen Associated REAPER Project needs the Start offset and Title metadata embedded in the rendered file, make sure \"Embed title/date/time if not provided\" and \"Embed start offset (media position in project)\" in the REAPER Project Render Metadata are enabled before rendering the file."
reaper.ShowMessageBox("Installation completed! Restart Wwise to discover the new command.\n\n"..importantNote, "Open Associated REAPER Project", utils.OK_MESSAGE_BOX)

