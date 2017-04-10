function fontSize = GetReleaseFontSize()
   fontSize = 12;
   
   release = version('-release');
   releaseYear = str2num(release(1:length(release)-1));  
   releaseLetter = release(length(release));
   
   platform = GetPlatform();
   
   if ((strcmp(platform.Platform,'windows') == 1) && releaseYear+releaseLetter < 2015+'b')
       fontSize = 14;
   end
end

