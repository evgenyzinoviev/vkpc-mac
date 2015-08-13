set js to "{js}"

set allWindows to null
set allTabs to {}

set okTab_nowPlaying to null
set okTab_playlistFound to null
set okTab_lsSource to null
set okTab_recentlyPlayed to null 
set okTab_havePlaylist to null
set activeTab to null
set lastTab to null
set execTab to null
set outdatedTabs to {}
--set tabsWithPlayingMusic to {}

set vkTabFound to 0
set lsSourceId to null
set playlistID to {playlistID}
set returnValue to 0
set command to "{command}"
set appPlaylistFound to 0
set appName to "{appName}"

if application "{appName}" is running then
    tell application "{appName}"
        set allWindows to every window
        
        repeat with currentWindow in allWindows
            try
                set allTabs to allTabs & every tab of currentWindow
            onsuccess
                if activeTab is null and class of ({ASCurrentTab} of currentWindow) is tab then set activeTab to ({ASCurrentTab} of currentWindow)
            end try
        end repeat
        
        repeat with currentTab in allTabs
            try
                set tabURL to (URL of currentTab)
                set tabTitle to ({ASTabTitle} currentTab)

                if tabTitle is not equal to "" then
                  if (tabURL starts with "http://vk.com" or tabURL starts with "https://vk.com") and tabURL does not contain "view-source:" then
                    set vkTabFound to 1
                    tell currentTab to {ASExecuteJS} js

                    set results to result

                    -- only for injection timer
                    if command is "afterInjection" then
                      -- set injectResult to item 1 of results
                      set _plid to item 6 of results
                      set _havePlaylist to item 2 of results
                      set _isPlaying to item 3 of results
                      
                      if _plid is not 0 and _plid is playlistID then
                        set appPlaylistFound to 1
                      end if

                      if _havePlaylist is 1 and _plid is not 0 and _plid is not playlistID then
                        set end of outdatedTabs to currentTab
                      end if

                      if _havePlaylist is 1 then 
                        set okTab_havePlaylist to currentTab
                      end if
                      
                      if _isPlaying is 1 then
                        set okTab_nowPlaying to currentTab
                      end if
                    else 
                      -- get global info (for first time)
                      -- try
                        if lsSourceId is null then
                          -- tell currentTab to {ASExecuteJS} "VKPC.getLastInstanceId()"
                          set lsSourceId to item 7 of results
                        end if
                      -- end try
                      
                      -- get tab info
                      -- tell currentTab to {ASExecuteJS} "VKPC.getParams()"
                      -- set params to result
                      
                      try
                        set _havePlayer to item 1 of results
                        set _havePlaylist to item 2 of results
                        set _isPlaying to item 3 of results
                        set _tabId to item 4 of results
                        set _trackId to item 5 of results
                        set _playlistId to item 6 of results

                        -- for safari: track all tabs with now playing music
                        --if appName is "Safari" and _isPlaying is true then
                        --  set end of tabsWithPlayingMusic to currentTab
                        --end if

                        -- check playlist id
                        if playlistID is not 0 and _playlistId is playlistID then 
                          set okTab_playlistFound to currentTab
                        end if

                        -- set last VK tab
                        set lastTab to currentTab
                        
                        -- set recently played tab
                        if _havePlayer and ( _isPlaying or class of _trackId is text ) then
                          set okTab_recentlyPlayed to currentTab
                        end if

                        -- set now playing tab
                        if _isPlaying = true then
                          set okTab_nowPlaying to currentTab
                        end if
                        
                        -- set 'found by ls source' tab
                        if lsSourceId is not null and lsSourceId is not missing value and lsSourceId is _tabId then
                          set okTab_lsSource to currentTab
                        end if
                      end try
                    end if
                  end if
                end if
            end try
        end repeat

        set execCommand to "VKPC.executeCommand('{command}', {playlistID})"

        if command is not "afterInjection" then 
          set tabsToCheck to {}
          if appName is "Safari" then
            set end of tabsToCheck to okTab_playlistFound
            set end of tabsToCheck to okTab_nowPlaying
          else
            set end of tabsToCheck to okTab_nowPlaying
            set end of tabsToCheck to okTab_playlistFound
          end if

          set end of tabsToCheck to okTab_lsSource
          set end of tabsToCheck to okTab_recentlyPlayed
          set end of tabsToCheck to okTab_havePlaylist
          set end of tabsToCheck to activeTab
          set end of tabsToCheck to lastTab
          
          set finExecTab to null

          repeat with execTab in tabsToCheck
            if class of execTab is tab then
              tell execTab to {ASExecuteJS} execCommand
              set finExecTab to execTab
              exit repeat
            end if
          end repeat
        else 
          if appPlaylistFound is 0 then
            if okTab_nowPlaying is not null then
              tell okTab_nowPlaying to {ASExecuteJS} execCommand
            else if okTab_havePlaylist is not null then
              tell okTab_havePlaylist to {ASExecuteJS} execCommand
            else 
              set returnValue to 1
            end if
          end if

          repeat with outdatedTab in outdatedTabs
            tell outdatedTab to {ASExecuteJS} "VKPC.clearPlaylist(true, 'as')"
          end repeat
        end if

        if vkTabFound is 0 then set returnValue to 1
    end tell
end if

return returnValue
