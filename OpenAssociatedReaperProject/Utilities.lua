--[[
  @description Utilities
  @author Audiokinetic
  @noindex
  @provides
    [nomain] . https://raw.githubusercontent.com/audiokinetic/Reaper-Tools/$commit/OpenAssociatedReaperProject/Utilities.lua
  @about
    Contains utility functions and constant used by the others scripts of the Open Associated REAPER Project package.
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

local Utilities = {}

-- constants --
Utilities.OK_RESULT = 1
Utilities.CANCEL_RESULT = 2
Utilities.OK_MESSAGE_BOX = 0
Utilities.OK_CANCEL_MESSAGE_BOX = 1
Utilities.TRACK_VIEW_ID = 1000
Utilities.CURRENT_PROJECT = 0
Utilities.SEPARATOR_CHAR = string.find(reaper.GetOS(), "Win") ~= nil and "\\" or "/"
local BROWSER_CMD = string.find(reaper.GetOS(), "Win") ~= nil and "start" or "open"

-- helper functions --
function Utilities.WindowsOS()
  return string.find(reaper.GetOS(), "Win") == 1
end

function Utilities.openUrl(url)
  os.execute(BROWSER_CMD .. ' "" "' .. url .. '"')
end

function Utilities.getReaperPath()
  local reaperPath = tostring(reaper.GetExePath())
  if Utilities.WindowsOS() then
    reaperPath = reaperPath.."\\"
    reaperPath = reaperPath:gsub("\\", "\\\\")
  else
    reaperPath = reaperPath.."/"
  end
  return reaperPath
end

function Utilities.getAppData()
  local appData = ""
  if not Utilities.WindowsOS() then
    appData = os.getenv("HOME").."/Library/Application Support"
  else
    appData = os.getenv("APPDATA")
  end
  return appData
end

function Utilities.getMetadata(pcmSource, list)
  for i = 1, #list do
    local _, candidate = reaper.GetMediaFileMetadata(pcmSource, list[i])

    if candidate and candidate ~= "" then
      return candidate
    end
  end

  return nil
end

function Utilities.getParentDirectory(path)
  local pathReversed = string.reverse(path)

  local nextSeperatorChar = string.find(pathReversed, Utilities.SEPARATOR_CHAR, 1)

  return string.sub(path, 0, string.len(path) - nextSeperatorChar)
end

-- JS dependency check --
function Utilities.JSDependencyCheck()
  if not reaper.JS_Window_FindChildByID or not reaper.JS_Window_Find or not reaper.JS_Window_SetScrollPos or not reaper.JS_Dialog_BrowseForFolder then
      local selectedOption = reaper.ShowMessageBox("The script requires the latest version of js_ReaScriptAPI be installed.\n\nView in ReaPack?", "Open Associated REAPER Project: Failed", Utilities.OK_CANCEL_MESSAGE_BOX)

      if selectedOption == Utilities.OK_RESULT then
        if reaper.ReaPack_BrowsePackages then
          reaper.ReaPack_BrowsePackages("js_ReaScriptAPI")
        else
          selectedOption = reaper.ShowMessageBox("Unable to locate ReaPack. You can download ReaPack by going to https://reapack.com.\n\nGo there now?", "Open Associated REAPER Project: Failed", Utilities.OK_CANCEL_MESSAGE_BOX)

          if selectedOption == Utilities.OK_RESULT then
            openUrl("https://reapack.com")
          end
        end
      end
      return false
  end
  return true
end

-- REAPER minimum version requirement check
function Utilities.ReaperMinimumVersionCheck()
  local version = reaper.GetAppVersion()
  version = version:match("[0-9]+%.[0-9]+")
  if tonumber(version) < 6.80 then
    reaper.ShowMessageBox("The required minimum version of REAPER is v6.80. Please update REAPER before running this script.", "Open Associated REAPER Project", 0)
    return false
  end
  return true
end

return Utilities