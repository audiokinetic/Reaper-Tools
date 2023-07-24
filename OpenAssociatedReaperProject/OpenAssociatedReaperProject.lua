@description Open Associated REAPER Project
@author Audiokinetic
@version 1.0.0
@metapackage
@provides
  [nomain] Utilities.lua https://raw.githubusercontent.com/audiokinetic/Reaper-Tools/$commit/OpenAssociatedReaperProject/Utilities.lua
  [nomain] OpenAssociatedReaperProject_Script.lua https://raw.githubusercontent.com/audiokinetic/Reaper-Tools/$commit/OpenAssociatedReaperProject/OpenAssociatedReaperProject_Script.lua
  [main] OpenAssociatedReaperProject_Install Wwise Command.lua https://raw.githubusercontent.com/audiokinetic/Reaper-Tools/$commit/OpenAssociatedReaperProject/OpenAssociatedReaperProject_Install%20Wwise%20Command.lua
@changelog
  Initial release.
@about
  # Open Associated REAPER Project
  The Open Associated REAPER Project package allows you to open the associated REAPER project of a rendered wav file used in a Wwise project.
  The package consists of three scripts:
   - OpenAssociatedReaperProject_Install Wwise Command.lua installs the "Open Associated REAPER Project" Wwise command to open the associated REAPER project of a rendered wav file an configure the root lookup directory for the REAPER source projects.
   - OpenAssociatedReaperProject_Script.lua is used by the Wwise command to find the associated project and region from the wav file.
   - Utilities.lua expose utilities and helper functions for the previous two scripts.

  ## Setup
  To complete the installation, run the OpenAssociatedReaperProject_Install Wwise Command.lua action.

  It will install the Wwise custom command: "Open Associated REAPER Project" and configure your REAPER projects root directory.
  The same action can be use to update the REAPER projects root directory.

  ## Minimum Requirements
  REAPER v6.80
  ### Important Note
  Open Associated REAPER Project needs the Start offset and Title metadata embedded in the rendered file, make sure "Embed title/date/time if not provided" and "Embed start offset (media position in project)" in the REAPER Project Render Metadata are enabled before rendering the file.


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