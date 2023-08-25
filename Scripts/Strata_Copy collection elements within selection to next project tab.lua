--[[
  @description Copy Collection Elements Within Selection To Next Project Tab
  @author Audiokinetic
  @version 0.0.1a
  @changelog
    Initial release.
  @about
    # Copy Collection Elements Within Selection To Next Project Tab
    This script will identify regions and clips within user's time selection, hide any tracks that are not parents and have NO items - or tracks that are purposefully muted.
    Project content is then copied from the current project tab to the next open project tab to the immediate right.

    ## Setup
    User should have a Strata (or other) collection project open and the desired project they would like to copy strata takes/regions etc. into. The destination project should be the NEXT tab to the right
    of the source/Strata project. Make a selection in the source project timeline and run the script.

    ## Contributing
    The repository is not open to pull request but in the case of a bug report, bugfix or a suggestions, please feel free to contact us
    via the [feature request section](http://www.audiokinetic.com/qa/feature-requests/) of Audiokinetic's Community Q&A. 

    ## Legal
    Copyright (c) 2023 [Audiokinetic Inc.](https://audiokinetic.com) All rights reserved.

    ## License
    Copyright (c) 2023 AUDIOKINETIC Inc.

    The script in this file is licensed to use under the license available at:
    https://raw.githubusercontent.com/audiokinetic/Reaper-Tools/main/License.txt (the "License").
    You may not use this file except in compliance with the License.

    Unless required by applicable law or agreed to in writing, software distributed
    under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
    CONDITIONS OF ANY KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations under the License.
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

-- Command IDs used for reaper.Main_OnCommand()
local EDIT_UNDO = 40029                      -- Edit: Undo
local SELECT_ALL_ITEMS = 40182               -- Item: Select all items
local COPY_TRACKS = 40210                    -- Track: Copy tracks
local ACTIVATE_NEXT_PROJECT_TAB = 40861      -- Next project tab
local ACTIVATE_PREVIOUS_PROJECT_TAB = 40862  -- Previous project tab
local PASTE_TRACKS_IN_PROJECT = 41221        -- Item: Paste items/tracks at mouse position

local currentProj = reaper.EnumProjects(-1)

local time_sel_start, time_sel_end = reaper.GetSet_LoopTimeRange2(currentProj, false, false, 0, 0, false)
if time_sel_start == time_sel_end then
  assert(nil, "There is nothing to copy. Please make a time selection.")
  return
end

local all_tracks = {}
local track_children = {}

-- Collect all tracks AND identify items that are within the time selection
local item_buffer = {}
local track_count = reaper.CountTracks(currentProj)
for i = 0, track_count - 1 do
  local track = reaper.GetTrack(currentProj, i)
  table.insert(all_tracks, track)

  local parent_track = reaper.GetParentTrack(track)
  if parent_track then
    if not track_children[parent_track] then
      track_children[parent_track] = {}
    end
    table.insert(track_children[parent_track], track)
  end

  local item_count = reaper.CountTrackMediaItems(track)
  for j = 0, item_count - 1 do
    local item = reaper.GetTrackMediaItem(track, j)
    local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")

    if item_pos < time_sel_start or item_pos > time_sel_end then
      table.insert(item_buffer, {track = track, item = item})
    end
  end
end

-- Begin Undo Block
reaper.Undo_BeginBlock()

-- Delete items outside time selection
for _, data in ipairs(item_buffer) do
  reaper.DeleteTrackMediaItem(data.track, data.item)
end

-- This recursive function returns true for tracks that should be copied
local function should_copy_track(track)
  if reaper.CountTrackMediaItems(track) > 0 then
    return true
  elseif reaper.GetMediaTrackInfo_Value(track, "B_MUTE") == 1 then
    return false
  end

  local children = track_children[track]
  if children then
    for _, child_track in ipairs(children) do
      if should_copy_track(child_track) then
        return true
      end
    end
  end
end

-- Hide tracks that are muted or have no items or only have children that must be hidden
for _, track in ipairs(all_tracks) do
  if not should_copy_track(track) then
    reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 0)
    reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 0)
  end
end

-- Select and copy items and tracks
reaper.Main_OnCommand(SELECT_ALL_ITEMS, 0)
reaper.Main_OnCommand(COPY_TRACKS, 0)

-- Collect regions inside the time selection
local regions_to_copy = {}
local num_markers_and_regions = reaper.CountProjectMarkers(currentProj)
for i = 0, num_markers_and_regions - 1 do
  local _, is_rgn, pos, rgn_end, name, id, color = reaper.EnumProjectMarkers3(currentProj, i)
  if is_rgn and pos >= time_sel_start and rgn_end <= time_sel_end then
    table.insert(regions_to_copy, {pos = pos, rgn_end = rgn_end, name = name, id = id, color = color})
  end
end

reaper.TrackList_AdjustWindows(false)
reaper.UpdateArrange()

-- End Undo Block
local UNDO_ENDBLOCK_DO_NOT_ADD_TO_UNDO_HISTORY = -1
reaper.Undo_EndBlock("Remove contents outside time sel", UNDO_ENDBLOCK_DO_NOT_ADD_TO_UNDO_HISTORY)

reaper.Main_OnCommand(EDIT_UNDO, 0)

-- Activate the other open project window and paste tracks and regions
reaper.Main_OnCommand(ACTIVATE_NEXT_PROJECT_TAB, 0)

-- Begin Undo Block
reaper.Undo_BeginBlock()

reaper.Main_OnCommand(PASTE_TRACKS_IN_PROJECT, 0)
for _, region in ipairs(regions_to_copy) do
  reaper.AddProjectMarker2(0, true, region.pos, region.rgn_end, region.name, -1, region.color)
end

-- End Undo Block
reaper.Undo_EndBlock("Pasted tracks and items", 0)

-- Uncomment the next line to go back to the previous tab after script execution
--reaper.Main_OnCommand(ACTIVATE_PREVIOUS_PROJECT_TAB, 0)
