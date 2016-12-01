





AutoDrive = {}; 
AutoDrive.Version = "0.8.1";
AutoDrive.config_changed = false;

AutoDrive.directory = g_currentModDirectory;


function AutoDrive:prerequisitesPresent(specializations)
    return true;
end;

function AutoDrive:delete()	

end;

function AutoDrive:MarkChanged()
	AutoDrive.config_changed = true;
	g_currentMission.AutoDrive.handledRecalculation = false;
end;

function AutoDrive:GetChanged()
	return AutoDrive.config_changed;
end;

function AutoDrive:loadMap(name)
	local aNameSearch = {"vehicle.name." .. g_languageShort, "vehicle.name.en", "vehicle.name", "vehicle.storeData.name", "vehicle#type"};
	
	if Steerable.load ~= nil then 
		local orgSteerableLoad = Steerable.load 
		Steerable.load = function(self,xmlFile) 
			orgSteerableLoad(self,xmlFile) 
			for nIndex,sXMLPath in pairs(aNameSearch) do 
				self.name = getXMLString(self.xmlFile, sXMLPath); 
				if self.name ~= nil then 
					break; 
				end; 
			end; 
			if self.name == nil then 
				self.name = g_i18n:getText("UNKNOWN")
			end; 
		end
	
	end;
	
	if g_currentMission.AutoDrive_printedDebug ~= true then
		--DebugUtil.printTableRecursively(g_currentMission, "	:	",0,2);
		print("Map title: " .. g_currentMission.missionInfo.map.title);
		if g_currentMission.missionInfo.savegameDirectory ~= nil then 
			print("Savegame location: " .. g_currentMission.missionInfo.savegameDirectory);
		else
			if g_currentMission.missionInfo.savegameIndex ~= nil then
				print("Savegame location via index: " .. getUserProfileAppPath() .. "savegame" .. g_currentMission.missionInfo.savegameIndex);
			else
				print("No savegame located");
			end;
		end;
		
		g_currentMission.AutoDrive_printedDebug = true;
	end;
	
	self.loadedMap = g_currentMission.missionInfo.map.title;
	self.loadedMap = string.gsub(self.loadedMap, " ", "_");
	self.loadedMap = string.gsub(self.loadedMap, "%.", "_");
	g_currentMission.autoLoadedMap = self.loadedMap;
	
	print("map " .. self.loadedMap .. " was loaded");
end;

function AutoDrive:deleteMap()
	
	--print("delete map called");
	
	if AutoDrive:GetChanged() == true and g_server ~= nil then
	
		if g_currentMission.AutoDrive.adXml ~= nil then
			local adXml = g_currentMission.AutoDrive.adXml;
			
			setXMLString(adXml, "AutoDrive.Version", AutoDrive.Version);
			if g_currentMission.AutoDrive.handledRecalculation ~= true then
				setXMLString(adXml, "AutoDrive.Recalculation", "true");	
				print("AD: Set to recalculating routes");

			else
				setXMLString(adXml, "AutoDrive.Recalculation", "false");
				print("AD: Set to not recalculating routes");
			end;
			
			
			local idFullTable = {};
			local idString = "";
			
			local xTable = {};
			local xString = "";
			
			local yTable = {};
			local yString = "";
			
			local zTable = {};
			local zString = "";
			
			local outTable = {};
			local outString = "";
			
			local incomingTable = {};
			local incomingString = "";
			
			local out_costTable = {};
			local out_costString = "";
			
			local markerNamesTable = {};
			local markerNames = "";
			
			local markerIDsTable = {};
			local markerIDs = "";
			
			for i,p in pairs(g_currentMission.AutoDrive.mapWayPoints) do
			
				--idString = idString .. p.id .. ",";
				idFullTable[i] = p.id;
				--xString = xString .. p.x .. ",";
				xTable[i] = p.x;
				--yString = yString .. p.y .. ",";
				yTable[i] = p.y;
				--zString = zString .. p.z .. ",";
				zTable[i] = p.z;
				
				--outString = outString .. table.concat(p.out, ",") .. ";";
				outTable[i] = table.concat(p.out, ",");
					
				local innerIncomingTable = {};
				local innerIncomingCounter = 1;
				for i2, p2 in pairs(g_currentMission.AutoDrive.mapWayPoints) do
					for i3, out2 in pairs(p2.out) do
						if out2 == p.id then
							innerIncomingTable[innerIncomingCounter] = p2.id;
							innerIncomingCounter = innerIncomingCounter + 1;
							--incomingString = incomingString .. p2.id .. ",";
						end;
					end;
				end;
				incomingTable[i] = table.concat(innerIncomingTable, ",");
				--incomingString = incomingString .. ";";
				
				out_costTable[i] = table.concat(p.out_cost, ",");
				--out_costString = out_costString .. table.concat(p.out_cost, ",") .. ";";
					
				local markerCounter = 1;
				local innerMarkerNamesTable = {};
				local innerMarkerIDsTable = {};
				for i2,marker in pairs(p.marker) do
					innerMarkerIDsTable[markerCounter] = marker;
					--markerIDs = markerIDs .. marker .. ",";
					innerMarkerNamesTable[markerCounter] = i2;
					--markerNames = markerNames .. i2 .. ",";
					markerCounter = markerCounter + 1;
				end;
				markerNamesTable[i] = table.concat(innerMarkerNamesTable, ",");
				markerIDsTable[i] = table.concat(innerMarkerIDsTable, ",");
				
				--markerIDs = markerIDs .. ";";
				--markerNames = markerNames .. ";";
			end;
			
			if idFullTable[1] ~= nil then
							
				setXMLString(adXml, "AutoDrive." .. self.loadedMap .. ".waypoints.id" , table.concat(idFullTable, ",") );
				setXMLString(adXml, "AutoDrive." .. self.loadedMap .. ".waypoints.x" , table.concat(xTable, ","));
				setXMLString(adXml, "AutoDrive." .. self.loadedMap .. ".waypoints.y" , table.concat(yTable, ","));
				setXMLString(adXml, "AutoDrive." .. self.loadedMap .. ".waypoints.z" , table.concat(zTable, ","));
				setXMLString(adXml, "AutoDrive." .. self.loadedMap .. ".waypoints.out" , table.concat(outTable, ";"));
				setXMLString(adXml, "AutoDrive." .. self.loadedMap .. ".waypoints.incoming" , table.concat(incomingTable, ";") );
				setXMLString(adXml, "AutoDrive." .. self.loadedMap .. ".waypoints.out_cost" , table.concat(out_costTable, ";"));
				if markerIDsTable[1] ~= nil then
					setXMLString(adXml, "AutoDrive." .. self.loadedMap .. ".waypoints.markerID" , table.concat(markerIDsTable, ";"));
					setXMLString(adXml, "AutoDrive." .. self.loadedMap .. ".waypoints.markerNames" , table.concat(markerNamesTable, ";"));
				end;
			end;
			
			for i in pairs(g_currentMission.AutoDrive.mapMarker) do
		
				setXMLFloat(adXml, "AutoDrive." .. self.loadedMap .. ".mapmarker.mm".. i ..".id", g_currentMission.AutoDrive.mapMarker[i].id);
				setXMLString(adXml, "AutoDrive." .. self.loadedMap .. ".mapmarker.mm".. i ..".name", g_currentMission.AutoDrive.mapMarker[i].name);			
			
			end;
			
			saveXMLFile(adXml);
		end;
	end;
	
end;

function AutoDrive:load(xmlFile)
	if g_currentMission.AutoDrive == nil then
		--print("not present");
		g_currentMission.AutoDrive = {};
		g_currentMission.AutoDrive.mapWayPoints = {};
		g_currentMission.AutoDrive.mapWayPointsCounter = 1;
		g_currentMission.AutoDrive.mapMarker = {};
		g_currentMission.AutoDrive.mapMarkerCounter = 0;
		g_currentMission.AutoDrive.showMouse = false;
				
		--loading savefile
		local adXml;
		local path = g_currentMission.missionInfo.savegameDirectory --getUserProfileAppPath();
		local file = "";
		if path ~= nil then
			file = path .."/AutoDrive_config.xml";
		else
			file = getUserProfileAppPath() .. "savegame" .. g_currentMission.missionInfo.savegameIndex  .. "/AutoDrive_config.xml";
		end;
		local tempXml = nil;
		
		if fileExists(file) then
			print("AD: Loading xml file from " .. file);
			g_currentMission.AutoDrive.xmlSaveFile = file;
			adXml = loadXMLFile("AutoDrive_XML", file);--, "AutoDrive");
			
			local VersionCheck = getXMLString(adXml, "AutoDrive.version");
			local MapCheck = hasXMLProperty(adXml, "AutoDrive." .. g_currentMission.autoLoadedMap );
			if VersionCheck == nil or VersionCheck ~= AutoDrive.Version or MapCheck == false then
				print("AD: Version Check or Map check failed - Loading init config");
				--[[
				print("AD: Saving your config as backup_config");

				infile = io.open(file, "r")
				instr = infile:read("*a")
				infile:close()

				if path ~= nil then
					file = path .."/AutoDrive_config.xml";
				else
					file = getUserProfileAppPath() .. "savegame" .. g_currentMission.missionInfo.savegameIndex  .. "/AutoDrive_backup_config.xml";
				end;

				outfile = io.open(file, "w")
				outfile:write(instr)
				outfile:close()
				--]]


				path = getUserProfileAppPath();
				file = path .. "/mods/AutoDrive/AutoDrive_init_config.xml";
				

				tempXml = loadXMLFile("AutoDrive_XML_temp", file);--, "AutoDrive");
				local MapCheckInit= hasXMLProperty(tempXml, "AutoDrive." .. g_currentMission.autoLoadedMap );
				if MapCheckInit == false then
					print("AD: Init config does not contain any information for this map. Existing Config will not be overwritten");
					tempXml = nil;
				end;
				
				--local tempstring = saveXMLFileToMemory(tempXml);
				--adXml = loadXMLFileFromMemory("AutoDrive_XML", tempstring);
				print("AD: Finished loading xml from memory");
				
				--AutoDrive:MarkChanged();
				
			end;
			
			--print("Finished loading xml");
				
		else --create std file instead:
			path = getUserProfileAppPath();
			file = path .. "/mods/AutoDrive/AutoDrive_init_config.xml";
			
			print("AD: Loading xml file from init config");
			tempXml = loadXMLFile("AutoDrive_XML_temp", file);--, "AutoDrive");
			--local tempstring = saveXMLFileToMemory(tempXml);
			--adXml = loadXMLFileFromMemory("AutoDrive_XML", tempstring);
			print("AD: Finished loading xml from memory");
			
			AutoDrive:MarkChanged();
			
			path = g_currentMission.missionInfo.savegameDirectory -- getUserProfileAppPath();
			if path ~= nil then
				file = path .."/AutoDrive_config.xml";
			else
				file = getUserProfileAppPath() .. "savegame" .. g_currentMission.missionInfo.savegameIndex  .. "/AutoDrive_config.xml";
			end;
			print("AD: creating xml file at " .. file);
			adXml = createXMLFile("AutoDrive_XML", file, "AutoDrive");
						
			saveXMLFile(adXml);
			g_currentMission.AutoDrive.xmlSaveFile = file;
		end;
			
		
		local backupXml = false;
		if adXml ~= nil then
			--print("Loading waypoints");
			if tempXml ~= nil then
				print("Loading from init file");
				backupXml = true;
				path = getUserProfileAppPath();
				file = path .. "/mods/AutoDrive/AutoDrive_init_config.xml";
				adXml = loadXMLFile("AutoDrive_XML_temp", file);--, "AutoDrive");
			end;
			g_currentMission.AutoDrive.adXml = adXml;
			--print("retrieving waypoints");
			--print("map " .. g_currentMission.autoLoadedMap .. " waypoints are loaded");
			self.loadedMap = g_currentMission.autoLoadedMap;
			if self.loadedMap ~= nil then --g_currentMission.autoLoadedMap == "Goldcrest" then 
				
				local idString = getXMLString(adXml, "AutoDrive." .. self.loadedMap .. ".waypoints.id");
				local idTable = Utils.splitString("," , idString);
				local xString = getXMLString(adXml, "AutoDrive." .. self.loadedMap .. ".waypoints.x");
				local xTable = Utils.splitString("," , xString);
				local yString = getXMLString(adXml, "AutoDrive." .. self.loadedMap .. ".waypoints.y");
				local yTable = Utils.splitString("," ,yString);
				local zString = getXMLString(adXml, "AutoDrive." .. self.loadedMap .. ".waypoints.z");
				local zTable = Utils.splitString("," , zString);
				
				local outString = getXMLString(adXml, "AutoDrive." .. self.loadedMap .. ".waypoints.out");
				local outTable = Utils.splitString(";" , outString);
				local outSplitted = {};
				for i, outer in pairs(outTable) do
					local out = Utils.splitString("," , outer);
					outSplitted[i] = out;					
				end;
				
				local incomingString = getXMLString(adXml, "AutoDrive." .. self.loadedMap .. ".waypoints.incoming");
				local incomingTable = Utils.splitString(";" , incomingString);
				local incomingSplitted = {};
				for i, outer in pairs(incomingTable) do
					local incoming = Utils.splitString("," , outer);
					incomingSplitted[i] = incoming;					
				end;
				
				local out_costString = getXMLString(adXml, "AutoDrive." .. self.loadedMap .. ".waypoints.out_cost");
				local out_costTable = Utils.splitString(";" , out_costString);
				local out_costSplitted = {};
				for i, outer in pairs(out_costTable) do
					local out_cost = Utils.splitString("," , outer);
					out_costSplitted[i] = out_cost;					
				end;
				
				local markerIDString = getXMLString(adXml, "AutoDrive." .. self.loadedMap .. ".waypoints.markerID");
				local markerIDTable = Utils.splitString(";" , markerIDString);
				local markerIDSplitted = {};
				for i, outer in pairs(markerIDTable) do
					local markerID = Utils.splitString("," , outer);
					markerIDSplitted[i] = markerID;					
				end;
				
				local markerNamesString = getXMLString(adXml, "AutoDrive." .. self.loadedMap .. ".waypoints.markerNames");
				local markerNamesTable = Utils.splitString(";" , markerNamesString);
				local markerNamesSplitted = {};
				for i, outer in pairs(markerNamesTable) do
					local markerNames = Utils.splitString("," , outer);
					markerNamesSplitted[i] = markerNames;					
				end;
				
				local wp_counter = 0;
				for i, id in pairs(idTable) do
					if id ~= "" then
						wp_counter = wp_counter +1;
						local wp = {};
						wp["id"] = tonumber(id);
						wp["out"] = {};
						for i2,outString in pairs(outSplitted[i]) do
							wp["out"][i2] = tonumber(outString);
						end;				
						
						wp["incoming"] = {};
						local incoming_counter = 1;
						for i2, incomingID in pairs(incomingSplitted[i]) do
							if incomingID ~= "" then
								wp["incoming"][incoming_counter] = tonumber(incomingID);
							end;
							incoming_counter = incoming_counter +1;
						end;
						
						wp["out_cost"] = {};
						for i2,out_costString in pairs(out_costSplitted[i]) do
							wp["out_cost"][i2] = tonumber(out_costString);
						end;
						
						wp["marker"] = {};
						for i2, markerName in pairs(markerNamesSplitted[i]) do
							if markerName ~= "" then
								wp.marker[markerName] = tonumber(markerIDSplitted[i][i2]);
							end;
						end;
						wp.x = tonumber(xTable[i]);
						wp.y = tonumber(yTable[i]);
						wp.z = tonumber(zTable[i]);
						
						g_currentMission.AutoDrive.mapWayPoints[wp_counter] = wp;			
					end;
					
				end;
				
				if g_currentMission.AutoDrive.mapWayPoints[wp_counter] ~= nil then
					print("AD: Loaded Waypoints: " .. wp_counter);
					g_currentMission.AutoDrive.mapWayPointsCounter = wp_counter;
				else
					g_currentMission.AutoDrive.mapWayPointsCounter = 0;
				end;
				
				--[[
				for i,p in pairs(g_currentMission.AutoDrive.mapWayPoints) do
					if i == 1 or i == 3 or i == 1516 or i == 5443 then
						print("Debug printing out point: " .. i);
						print("     " .. i .. ".id:" .. p.id);						
						print("     " .. i .. ".x:" .. p.x);
						print("     " .. i .. ".y:" .. p.y);
						print("     " .. i .. ".z:" .. p.z);						
						print("     " .. i .. ".out:");
						for i2,out in pairs(p.out) do							
							print("          " .. out);
						end;
						print("     " .. i .. ".incoming:");
						for i2,incoming in pairs(p.incoming) do							
							print("          " .. incoming);
						end;
						print("     " .. i .. ".out_cost:");
						for i2,out_cost in pairs(p.out_cost) do							
							print("          " .. out_cost);
						end;
						print("     " .. i .. ".marker:");
						for markerName,markerID in pairs(p.marker) do							
							print("          " .. markerName .. " : " .. markerID);
						end;
					end;
						
				end;
				--]]
				
				local mapMarker = {};
				local mapMarkerCounter = 1;
				mapMarker.name = getXMLString(adXml,"AutoDrive." .. self.loadedMap ..".mapmarker.mm"..mapMarkerCounter..".name");
				
				while mapMarker.name ~= nil do
					--print("Loading map marker: " .. mapMarker.name);
					mapMarker.id = getXMLFloat(adXml,"AutoDrive." .. self.loadedMap ..".mapmarker.mm"..mapMarkerCounter..".id");
					
					g_currentMission.AutoDrive.mapMarker[mapMarkerCounter] = mapMarker;
					mapMarker = nil;
					mapMarker = {};
					mapMarkerCounter = mapMarkerCounter + 1;	
					g_currentMission.AutoDrive.mapMarkerCounter = g_currentMission.AutoDrive.mapMarkerCounter + 1;
					mapMarker.name = getXMLString(adXml,"AutoDrive." .. self.loadedMap ..".mapmarker.mm"..mapMarkerCounter..".name");
				end;
				--[[
				for i in pairs(g_currentMission.AutoDrive.mapWayPoints) do
					print("wp.id: " .. g_currentMission.AutoDrive.mapWayPoints[i].id);
				end;
				--]]
			else
				print("AutoDrive: Waypoints and markers are not yet supported on this map - Try it on Goldcrest");
			end;
				
			
			local recalculate = true;
			local recalculateString = getXMLString(adXml, "AutoDrive.Recalculation");
			if recalculateString == "true" then
				recalculate = true;
			end;
			if recalculateString == "false" then
				recalculate = false;
			end;
						
			if recalculate == true then
				for i2,point in pairs(g_currentMission.AutoDrive.mapWayPoints) do
					point.marker = {};
				end;
			
				print("AD: recalculating routes");
				for i, marker in pairs(g_currentMission.AutoDrive.mapMarker) do
					
					local tempAD = AutoDrive:dijkstra(g_currentMission.AutoDrive.mapWayPoints, marker.id,"incoming");
					
					for i2,point in pairs(g_currentMission.AutoDrive.mapWayPoints) do
								
						point.marker[marker.name] = tempAD.pre[point.id];
									
					end;
					
					
				end;
				setXMLString(adXml, "AutoDrive.Recalculation","false");
				AutoDrive:MarkChanged();
				g_currentMission.AutoDrive.handledRecalculation = true;
			else
				print("AD: Routes are already calculated");
			end;
			
			if backupXml == true then
				--print("Switching back to correct xml");
				path = g_currentMission.missionInfo.savegameDirectory --getUserProfileAppPath();
				local file = "";
				if path ~= nil then
					file = path .."/AutoDrive_config.xml";
					adXml = loadXMLFile("AutoDrive_XML", file);--, "AutoDrive");
				else
					file = getUserProfileAppPath() .. "savegame" .. g_currentMission.missionInfo.savegameIndex  .. "/AutoDrive_config.xml";
					print("AD: creating xml file at " .. file);
					adXml = createXMLFile("AutoDrive_XML", file, "AutoDrive");
						
					saveXMLFile(adXml);
				end;
				g_currentMission.AutoDrive.adXml = adXml;
			end;
			
		end;	
		AutoDrive:loadHud();
	end;


	AutoDrive.Triggers = {};
	AutoDrive.Triggers.tipTriggers = {};

	for _,trigger in pairs(g_currentMission.tipTriggers) do

		local triggerLocation = {};
		local x,y,z = getWorldTranslation(trigger.rootNode);
		triggerLocation.x = x;
		triggerLocation.y = y;
		triggerLocation.z = z;
		--print("trigger: " .. trigger.stationName .. " pos: " .. x .. "/" .. y .. "/" .. z);

	end;
	
end;

function AutoDrive:loadHud()
	
	if VehicleCamera.AutoDriveInserted == nil then
		VehicleCamera.mouseEvent = Utils.overwrittenFunction(VehicleCamera.mouseEvent, AutoDrive.newMouseEvent);
		print("AutoDrive mod inserted into Vehicle Camera")
		VehicleCamera.AutoDriveInserted = true;
	end;
		
		
	AutoDrive.Hud = {};
	AutoDrive.Hud.Speed = "40";
	AutoDrive.Hud.Target = "Not Ready"
	AutoDrive.Hud.showHud = true;
	if g_currentMission.AutoDrive.mapMarker[1] ~= nil then
		AutoDrive.Hud.Target = g_currentMission.AutoDrive.mapMarker[1].name;
	end;
	
	
	AutoDrive.Hud.Background = {};
	AutoDrive.Hud.Buttons = {};
	AutoDrive.Hud.buttonCounter = 0;
	AutoDrive.Hud.rows = 1;	
	AutoDrive.Hud.rowCurrent = 1;
	AutoDrive.Hud.cols = 7;
	AutoDrive.Hud.colCurrent = 1;
	
	
	AutoDrive.Hud.posX = 0.802;
	AutoDrive.Hud.posY = 0.207;
	AutoDrive.Hud.width = 0.181;
	AutoDrive.Hud.height = 0.110;
	AutoDrive.Hud.borderX = 0.004;
	AutoDrive.Hud.borderY = AutoDrive.Hud.borderX * (g_screenWidth / g_screenHeight);
	
	AutoDrive.Hud.buttonWidth = 0.02;
	AutoDrive.Hud.buttonHeight = AutoDrive.Hud.buttonWidth * (g_screenWidth / g_screenHeight);
	
	local img1 = Utils.getNoNil("img/ADHud_new.dds", "empty.dds" )
	local state, result = pcall( Utils.getFilename, img1, AutoDrive.directory )
	if not state then
		print("ERROR: "..tostring(result).." (img1: "..tostring(img1)..")")
		return
	end
	AutoDrive.Hud.Background.ov = Overlay:new(nil, result, AutoDrive.Hud.posX, AutoDrive.Hud.posY , AutoDrive.Hud.width, AutoDrive.Hud.height);
	AutoDrive.Hud.Background.posX = AutoDrive.Hud.posX;
	AutoDrive.Hud.Background.posY = AutoDrive.Hud.posY;
	AutoDrive.Hud.Background.width = AutoDrive.Hud.width;
	AutoDrive.Hud.Background.height = AutoDrive.Hud.height;
	AutoDrive.Hud.Background.img = result;
	
	--[[
	AutoDrive.Hud.Background.target = {};
	img1 = Utils.getNoNil("img/ADHud_new.dds", "empty.dds" )
	state, result = pcall( Utils.getFilename, img1, AutoDrive.directory )
	if not state then
		print("ERROR: "..tostring(result).." (img1: "..tostring(img1)..")")
		return
	end
	AutoDrive.Hud.Background.target.ov = Overlay:new(nil, result, AutoDrive.Hud.posX, AutoDrive.Hud.posY , AutoDrive.Hud.width, AutoDrive.Hud.height);
	AutoDrive.Hud.Background.target.posX = AutoDrive.Hud.posX;
	AutoDrive.Hud.Background.target.posY = AutoDrive.Hud.posY;
	AutoDrive.Hud.Background.target.width = AutoDrive.Hud.width;
	AutoDrive.Hud.Background.height = AutoDrive.Hud.height;
	AutoDrive.Hud.Background.img = result;
	--]]

	AutoDrive:AddButton("input_start_stop", "on.dds", "off.dds", false, true);
	AutoDrive:AddButton("input_previousTarget", "previousTarget.dds", "previousTarget.dds", true, true);
	AutoDrive:AddButton("input_nextTarget", "nextTarget.dds", "nextTarget.dds", true, true);
	AutoDrive:AddButton("input_record", "record_on.dds", "record_off.dds", false, true);
	AutoDrive:AddButton("input_silomode", "silomode_on.dds", "silomode_off.dds", false, true);
	AutoDrive:AddButton("input_decreaseSpeed", "decreaseSpeed.dds", "decreaseSpeed.dds", true, true);
	AutoDrive:AddButton("input_increaseSpeed", "increaseSpeed.dds", "increaseSpeed.dds", true, true);
	
	AutoDrive:AddButton("input_debug", "debug_on.dds", "debug_off.dds", false, true);
	AutoDrive:AddButton("input_showClosest", "showClosest_on.dds", "showClosest_off.dds", false, true);
	AutoDrive:AddButton("input_showNeighbor", "showNeighbor_on.dds", "showNeighbor_off.dds", false, true);
	AutoDrive:AddButton("input_nextNeighbor", "nextNeighbor.dds", "nextNeighbor.dds", true, true);
	AutoDrive:AddButton("input_toggleConnection", "toggleConnection.dds", "toggleConnection.dds", true, true);
	AutoDrive:AddButton("input_createMapMarker", "createMapMarker.dds", "createMapMarker.dds", true, true);
	AutoDrive:AddButton("input_toggleHud", "close.dds", "close.dds", true, true);
	
	
	AutoDrive:AddButton("input_recalculate", "recalculate.dds", "recalculate.dds", true, false);
	AutoDrive:AddButton("input_removeWaypoint", "deleteWaypoint.dds", "deleteWaypoint.dds", true, false);

end;

function AutoDrive:AddButton(name, img, img2, on, visible)
	
	AutoDrive.Hud.buttonCounter = AutoDrive.Hud.buttonCounter + 1;	
	AutoDrive.Hud.colCurrent = AutoDrive.Hud.buttonCounter % AutoDrive.Hud.cols;
	if AutoDrive.Hud.colCurrent == 0 then
		AutoDrive.Hud.colCurrent = AutoDrive.Hud.cols;
	end;
	AutoDrive.Hud.rowCurrent = math.ceil(AutoDrive.Hud.buttonCounter / AutoDrive.Hud.cols);	
	AutoDrive.Hud.Buttons[AutoDrive.Hud.buttonCounter] = {};
	local buttonImg = Utils.getNoNil("img/" .. img, "empty.dds" )
	local state, result = pcall( Utils.getFilename, buttonImg, AutoDrive.directory )
	if not state then
		print("ERROR: "..tostring(result).." (buttinImg: "..tostring(buttinImg)..")")
		return
	end
	AutoDrive.Hud.Buttons[AutoDrive.Hud.buttonCounter].posX = AutoDrive.Hud.posX + AutoDrive.Hud.borderX + AutoDrive.Hud.colCurrent * AutoDrive.Hud.borderX + (AutoDrive.Hud.colCurrent - 1) * AutoDrive.Hud.buttonWidth;
	AutoDrive.Hud.Buttons[AutoDrive.Hud.buttonCounter].posY = AutoDrive.Hud.posY + (AutoDrive.Hud.rowCurrent) * AutoDrive.Hud.borderY + (AutoDrive.Hud.rowCurrent-1) * AutoDrive.Hud.buttonHeight;
	AutoDrive.Hud.Buttons[AutoDrive.Hud.buttonCounter].width = AutoDrive.Hud.buttonWidth;
	AutoDrive.Hud.Buttons[AutoDrive.Hud.buttonCounter].height = AutoDrive.Hud.buttonHeight;
	AutoDrive.Hud.Buttons[AutoDrive.Hud.buttonCounter].name = name;
	AutoDrive.Hud.Buttons[AutoDrive.Hud.buttonCounter].img_on = result;
	AutoDrive.Hud.Buttons[AutoDrive.Hud.buttonCounter].isVisible = visible;
	
	if img2 ~= nil then 
		buttonImg = Utils.getNoNil("img/" .. img2, "empty.dds" )
		state, result = pcall( Utils.getFilename, buttonImg, AutoDrive.directory )
		if not state then
			print("ERROR: "..tostring(result).." (buttinImg: "..tostring(buttinImg)..")")
			return
		end	
		AutoDrive.Hud.Buttons[AutoDrive.Hud.buttonCounter].img_off = result;
	else
		AutoDrive.Hud.Buttons[AutoDrive.Hud.buttonCounter].img_off = nil;
	end;
	
	if on then
		AutoDrive.Hud.Buttons[AutoDrive.Hud.buttonCounter].img_active = AutoDrive.Hud.Buttons[AutoDrive.Hud.buttonCounter].img_on;
	else
		AutoDrive.Hud.Buttons[AutoDrive.Hud.buttonCounter].img_active = AutoDrive.Hud.Buttons[AutoDrive.Hud.buttonCounter].img_off;
	end;
	
	AutoDrive.Hud.Buttons[AutoDrive.Hud.buttonCounter].ov = Overlay:new(nil, AutoDrive.Hud.Buttons[AutoDrive.Hud.buttonCounter].img_active,AutoDrive.Hud.Buttons[AutoDrive.Hud.buttonCounter].posX ,AutoDrive.Hud.Buttons[AutoDrive.Hud.buttonCounter].posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
	

end;

function AutoDrive:InputHandling(vehicle, input)

	vehicle.currentInput = input;

	if g_server ~= nil then
		--print("received event in InputHandling. event: " .. input);
	else
		--print("Not the server - sending event to server " .. input);
		AutoDriveInputEvent:sendEvent(vehicle);
	end;

	if vehicle.currentInput ~= nil then
		--print("Checking if vehicle is currently controlled." .. input);
		--if vehicle == g_currentMission.controlledVehicle then
			--print("Executing InputHandling with input: " .. input);
			--print("correct vehicle");
			if input == "input_silomode" and g_dedicatedServerInfo == nil and g_server ~= nil then

				--print("executing input_silomode");
				if vehicle.bReverseTrack == false then
					vehicle.bReverseTrack = true;
					vehicle.bDrivingForward = true;
					vehicle.bTargetMode = false;
					vehicle.bRoundTrip = false;
					vehicle.nSpeed = 15;
					--print("reverse track = true");
					--vehicle.printMessage = g_i18n:getText("AD_Silomode_on");
					--vehicle.nPrintTime = 3000;
				else
					vehicle.bReverseTrack = false;
					vehicle.bDrivingForward = true;
					--print("reverse track = false");
					--vehicle.printMessage = g_i18n:getText("AD_Silomode_off");
					--vehicle.nPrintTime = 3000;
				end;


				for _,button in pairs(AutoDrive.Hud.Buttons) do
					if button.name == "input_silomode" then
						local buttonImg = "";
						if vehicle.bReverseTrack == true then
							button.img_active = button.img_on;
						else
							button.img_active = button.img_off;
						end;

						button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
					end;
				end;
			end;

			if input == "input_roundtrip" then
				if vehicle.bRoundTrip == false then
					vehicle.bRoundTrip = true;
					vehicle.nSpeed = 40;
					vehicle.bTargetMode = false;
					vehicle.bReverseTrack = false;
					--print("roundTrip = true");
					vehicle.printMessage = g_i18n:getText("AD_Roundtrip_on");
					vehicle.nPrintTime = 3000;

				else
					vehicle.bRoundTrip = false;
					--print("roundTrip = false");
					vehicle.printMessage = g_i18n:getText("AD_Roundtrip_off");
					vehicle.nPrintTime = 3000;
				end;

			end;

			if input == "input_record" and g_server ~= nil and g_dedicatedServerInfo == nil then
				if vehicle.bcreateMode == false then
					vehicle.bcreateMode = true;
					vehicle.nCurrentWayPoint = 0;
					vehicle.bActive = false;
					vehicle.ad.wayPoints = {};
					vehicle.bTargetMode = false;
					--vehicle.printMessage = g_i18n:getText("AD_Recording_on");
					--vehicle.nPrintTime = 3000;
				else
					vehicle.bcreateMode = false;
					--vehicle.printMessage = g_i18n:getText("AD_Recording_off");
					--vehicle.nPrintTime = 3000;
				end;

				for _,button in pairs(AutoDrive.Hud.Buttons) do
					if button.name == "input_record" then
						local buttonImg = "";
						if vehicle.bcreateMode == true then
							button.img_active = button.img_on;
						else
							button.img_active = button.img_off;
						end;
						button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
					end;
				end;

			end;

			if input == "input_start_stop" then
				--print("executing input_start_stop");
				if vehicle.bActive == false then
					vehicle.bActive = true;
					vehicle.bcreateMode = false;
					--vehicle.onStartAiVehicle();
					--vehicle.isHired = true;
					vehicle.forceIsActive = true;
					vehicle.stopMotorOnLeave = false;
					vehicle.disableCharacterOnLeave = true;
					--vehicle.isControlled = true;


					--vehicle.printMessage = g_i18n:getText("AD_Activated");
					vehicle.nPrintTime = 3000;
				else
					vehicle.nCurrentWayPoint = 0;
					vehicle.bDrivingForward = true;
					vehicle.bActive = false;
					vehicle.bStopAD = true;
					--AutoDrive:deactivate(vehicle,false);
				end;

				for _,button in pairs(AutoDrive.Hud.Buttons) do
					if button.name == "input_start_stop" then
						local buttonImg = "";
						if vehicle.bActive == true then
							button.img_active = button.img_on;
						else
							button.img_active = button.img_off;
						end;
						button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
					end;
				end;

			end;

			if input == "input_nextTarget" then
				--print("executing input_nextTarget");
				if  g_currentMission.AutoDrive.mapMarker[1] ~= nil and g_currentMission.AutoDrive.mapWayPoints[1] ~= nil then
					if vehicle.nMapMarkerSelected == -1 then
						vehicle.nMapMarkerSelected = 1

						vehicle.ntargetSelected = g_currentMission.AutoDrive.mapMarker[vehicle.nMapMarkerSelected].id;
						if vehicle.nSpeed == 15 then
							vehicle.nSpeed = 40;
						end;
						vehicle.sTargetSelected = g_currentMission.AutoDrive.mapMarker[vehicle.nMapMarkerSelected].name;
						local translation = AutoDrive:translate(vehicle.sTargetSelected);
						vehicle.sTargetSelected = translation;

						--vehicle.printMessage = g_i18n:getText("AD_Selected_Target") .. g_currentMission.AutoDrive.mapMarker[vehicle.nMapMarkerSelected].name;
						--vehicle.nPrintTime = 3000;
						vehicle.bTargetMode = true;
						vehicle.bRoundTrip = false;
						vehicle.bReverseTrack = false;
						vehicle.bDrivingForward = true;

					else
						vehicle.nMapMarkerSelected = vehicle.nMapMarkerSelected + 1;
						if vehicle.nMapMarkerSelected > g_currentMission.AutoDrive.mapMarkerCounter then
							vehicle.nMapMarkerSelected = 1;
						end;
						vehicle.ntargetSelected = g_currentMission.AutoDrive.mapMarker[vehicle.nMapMarkerSelected].id;
						vehicle.sTargetSelected = g_currentMission.AutoDrive.mapMarker[vehicle.nMapMarkerSelected].name;
						local translation = AutoDrive:translate(vehicle.sTargetSelected);
						vehicle.sTargetSelected = translation;
						if vehicle.nSpeed == 15 then
							vehicle.nSpeed = 40;
						end;
						--vehicle.printMessage = g_i18n:getText("AD_Selected_Target") .. g_currentMission.AutoDrive.mapMarker[vehicle.nMapMarkerSelected].name;
						--vehicle.nPrintTime = 3000;
						vehicle.bTargetMode = true;
					end;
				end;

			end;

			if input == "input_previousTarget" then
				--print("executing input_previousTarget");
				if g_currentMission.AutoDrive.mapMarker[1] ~= nil and g_currentMission.AutoDrive.mapWayPoints[1] ~= nil then
					if vehicle.nMapMarkerSelected == -1 then
						vehicle.nMapMarkerSelected = g_currentMission.AutoDrive.mapMarkerCounter;

						vehicle.ntargetSelected = g_currentMission.AutoDrive.mapMarker[vehicle.nMapMarkerSelected].id;
						if vehicle.nSpeed == 15 then
							vehicle.nSpeed = 40;
						end;
						vehicle.sTargetSelected = g_currentMission.AutoDrive.mapMarker[vehicle.nMapMarkerSelected].name;
						local translation = AutoDrive:translate(vehicle.sTargetSelected);
						vehicle.sTargetSelected = translation;
						--vehicle.printMessage = g_i18n:getText("AD_Selected_Target") .. g_currentMission.AutoDrive.mapMarker[vehicle.nMapMarkerSelected].name;
						--vehicle.nPrintTime = 3000;
						vehicle.bTargetMode = true;

					else
						vehicle.nMapMarkerSelected = vehicle.nMapMarkerSelected - 1;
						if vehicle.nMapMarkerSelected < 1 then
							vehicle.nMapMarkerSelected = g_currentMission.AutoDrive.mapMarkerCounter;
						end;
						vehicle.ntargetSelected = g_currentMission.AutoDrive.mapMarker[vehicle.nMapMarkerSelected].id;
						vehicle.sTargetSelected = g_currentMission.AutoDrive.mapMarker[vehicle.nMapMarkerSelected].name;
						local translation = AutoDrive:translate(vehicle.sTargetSelected);
						vehicle.sTargetSelected = translation;
						if vehicle.nSpeed == 15 then
							vehicle.nSpeed = 40;
						end;
						--vehicle.printMessage = g_i18n:getText("AD_Selected_Target") .. g_currentMission.AutoDrive.mapMarker[vehicle.nMapMarkerSelected].name;
						--vehicle.nPrintTime = 3000;
						vehicle.bTargetMode = true;
					end;

				end;
			end;

			if input == "input_debug"  then
				if vehicle.bCreateMapPoints == false then
					vehicle.bCreateMapPoints = true;
					--vehicle.printMessage = g_i18n:getText("AD_Debug_on");
					--vehicle.nPrintTime = 10000;
				else
					vehicle.bCreateMapPoints = false;
					--vehicle.printMessage = g_i18n:getText("AD_Debug_off")
					--vehicle.nPrintTime = 3000;
				end;

				for _,button in pairs(AutoDrive.Hud.Buttons) do
					if button.name == "input_debug" then
						local buttonImg = "";
						if vehicle.bCreateMapPoints == true then
							button.img_active = button.img_on;
						else
							button.img_active = button.img_off;
						end;
						button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
					end;
				end;

			end;

			if input == "input_showClosest" and g_server ~= nil and g_dedicatedServerInfo == nil then
				if vehicle.bShowDebugMapMarker == false then
					vehicle.bShowDebugMapMarker = true;
					--vehicle.printMessage = g_i18n:getText("AD_Debug_show_closest")
					--vehicle.nPrintTime = 10000;
				else
					vehicle.bShowDebugMapMarker = false;
					--vehicle.printMessage = g_i18n:getText("AD_Debug_show_closest_off")
					--vehicle.nPrintTime = 3000;
				end;

				for _,button in pairs(AutoDrive.Hud.Buttons) do
					if button.name == "input_showClosest" then
						local buttonImg = "";
						if vehicle.bShowDebugMapMarker == true then
							button.img_active = button.img_on;
						else
							button.img_active = button.img_off;
						end;
						button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
					end;
				end;

			end;

			if input == "input_showNeighbor" and g_server ~= nil and g_dedicatedServerInfo == nil then
				if vehicle.bShowSelectedDebugPoint == false then
					vehicle.bShowSelectedDebugPoint = true;

					local debugCounter = 1;
					for i,point in pairs(g_currentMission.AutoDrive.mapWayPoints) do
						local x1,y1,z1 = getWorldTranslation(vehicle.components[1].node);
						local distance = getDistance(point.x,point.z,x1,z1);

						if distance < 15 then
							vehicle.DebugPointsIterated[debugCounter] = point;
							debugCounter = debugCounter + 1;
						end;
					end;
					vehicle.nSelectedDebugPoint = 1;


					--vehicle.printMessage = g_i18n:getText("AD_Debug_show_closest_neighbors")
					--vehicle.nPrintTime = 10000;
				else
					vehicle.bShowSelectedDebugPoint = false;
				end;

				for _,button in pairs(AutoDrive.Hud.Buttons) do
					if button.name == "input_showNeighbor" then
						local buttonImg = "";
						if vehicle.bShowSelectedDebugPoint == true then
							button.img_active = button.img_on;
						else
							button.img_active = button.img_off;
						end;
						button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
					end;
				end;

			end;

			if input == "input_toggleConnection" and g_server ~= nil and g_dedicatedServerInfo == nil then
				if vehicle.bChangeSelectedDebugPoint == false then
					vehicle.bChangeSelectedDebugPoint = true;
					--vehicle.printMessage = g_i18n:getText("AD_Debug_change_connection");
					--vehicle.nPrintTime = 10000;
				else
					vehicle.bChangeSelectedDebugPoint = false;
					--vehicle.printMessage = g_i18n:getText("AD_Debug_not_ready");
					--vehicle.nPrintTime = 3000;
				end;

			end;

			if input == "input_nextNeighbor" then
				if vehicle.bChangeSelectedDebugPointSelection == false then
					vehicle.bChangeSelectedDebugPointSelection = true;
					--vehicle.printMessage = "Changing entry for highlighted markers";
					--vehicle.nPrintTime = 10000;
				else
					vehicle.bChangeSelectedDebugPointSelection = false;
					--vehicle.printMessage = "Not ready";
					--vehicle.nPrintTime = 3000;
				end;

			end;

			if input == "input_createMapMarker" and g_server ~= nil and g_dedicatedServerInfo == nil then
				if vehicle.bShowDebugMapMarker == true then
					if vehicle.bCreateMapMarker == false then
						vehicle.bCreateMapMarker  = true;
						vehicle.bEnteringMapMarker = true;
						vehicle.sEnteredMapMarkerString = "";
						g_currentMission.isPlayerFrozen = true;
						vehicle.isBroken = true;

						--g_currentMission.player.lockedInput = true;
						--g_currentMission.player.isEntered = false;
						--g_currentMission.player.isControlled = false;
						--g_currentMission.manualPaused = true;

						--g_currentMission.controlPlayer = false;
						--vehicle.printMessage = "Changing entry for highlighted markers";
						--vehicle.nPrintTime = 10000;

						--DebugUtil.printTableRecursively(InputBinding, ".",0,5);


					else
						vehicle.bCreateMapMarker  = false;
						vehicle.bEnteringMapMarker = false;
						vehicle.sEnteredMapMarkerString = "";
						g_currentMission.isPlayerFrozen = false;
						vehicle.isBroken = false;

						vehicle.printMessages = "Not ready";
						vehicle.nPrintTime = 3000;
					end;
				end;

			end;

			if input == "input_increaseSpeed" then
				if vehicle.nSpeed < 40 then
					vehicle.nSpeed = vehicle.nSpeed + 1;

				else
					vehicle.nSpeed = 40;
				end;
				--vehicle.printMessage = g_i18n:getText("AD_Speed_set_to") .. " " .. vehicle.nSpeed;
				--vehicle.nPrintTime = 2000;

			end;

			if input == "input_decreaseSpeed" then
				if vehicle.nSpeed > 5 then
					vehicle.nSpeed = vehicle.nSpeed - 1;

				else
					vehicle.nSpeed = 5;
				end;
				--vehicle.printMessage = g_i18n:getText("AD_Speed_set_to") .. " " .. vehicle.nSpeed;
				--vehicle.nPrintTime = 2000;

			end;

			if input == "input_toggleHud" then
				if AutoDrive.Hud.showHud == false then
					AutoDrive.Hud.showHud = true;
				else
					AutoDrive.Hud.showHud = false;
					if g_currentMission.AutoDrive.showMouse == false then
						--g_mouseControlsHelp.active = false
						g_currentMission.AutoDrive.showMouse = true;
						InputBinding.setShowMouseCursor(true);
					else
						--g_mouseControlsHelp.active = true
						InputBinding.setShowMouseCursor(false);
						g_currentMission.AutoDrive.showMouse = false;
					end;
				end;
			end;

		if input == "input_toggleMouse" then
			if AutoDrive.Hud.showHud == true then
				if g_currentMission.AutoDrive.showMouse == false then
					--g_mouseControlsHelp.active = false
					g_currentMission.AutoDrive.showMouse = true;
					InputBinding.setShowMouseCursor(true);
				else
					--g_mouseControlsHelp.active = true
					InputBinding.setShowMouseCursor(false);
					g_currentMission.AutoDrive.showMouse = false;
				end;
			end;
		end;

			if input == "input_removeWaypoint" and g_server ~= nil and g_dedicatedServerInfo == nil then

				if vehicle.bShowDebugMapMarker == true then
					local closest = AutoDrive:findClosestWayPoint(vehicle)
					print("removing waypoint with id: " .. closest);
					AutoDrive:removeMapWayPoint( g_currentMission.AutoDrive.mapWayPoints[closest] );
				end;

			end;

			if input == "input_recalculate" and g_server ~= nil and g_dedicatedServerInfo == nil then
				for i2,point in pairs(g_currentMission.AutoDrive.mapWayPoints) do
						point.marker = {};
					end;

					print("AD: recalculating routes");
					for i, marker in pairs(g_currentMission.AutoDrive.mapMarker) do

						local tempAD = AutoDrive:dijkstra(g_currentMission.AutoDrive.mapWayPoints, marker.id,"incoming");

						for i2,point in pairs(g_currentMission.AutoDrive.mapWayPoints) do

							point.marker[marker.name] = tempAD.pre[point.id];

						end;


					end;
					if g_currentMission.AutoDrive.adXml ~= nil then
						setXMLString(g_currentMission.AutoDrive.adXml, "AutoDrive.Recalculation","false");
						AutoDrive:MarkChanged();
						g_currentMission.AutoDrive.handledRecalculation = true;
					end;
			end;
		--end;
	end;
	vehicle.currentInput = "";

end;

function AutoDrive:onLeave()
	if g_currentMission.AutoDrive.showMouse then
		InputBinding.setShowMouseCursor(false);
		g_currentMission.AutoDrive.showMouse = false;
	end
end;

function AutoDrive:dijkstra(Graph,start,setToUse)
	
	--init
	--initdijkstra(Graph,Start,distance,pre,Q);
	if self.ad == nil then
		self.ad = {};--g_currentMission.AutoDrive.ad;
	end;
	
	self.ad.Q = AutoDrive:graphcopy(Graph);
	self.ad.distance = {};
	self.ad.pre = {};
	for i in pairs(Graph) do
		self.ad.distance[i] = -1;
		self.ad.pre[i] = -1;
	end;
	
	self.ad.distance[start] = 0;
	for i in pairs(self.ad.Q[start][setToUse]) do
		--print("out of start: " .. self.ad.Q[start][setToUse][i] );
		self.ad.distance[self.ad.Q[start][setToUse][i]] = 1 --self.ad.Q[start]["out_cost"][i];
		self.ad.pre[self.ad.Q[start][setToUse][i]] = start;
	end;
	--init end
	
	while next(self.ad.Q,nil) ~= nil do
		local shortest = 10000000;
		local shortest_id = -1;
		for i in pairs(self.ad.Q) do
			
			if self.ad.distance[self.ad.Q[i]["id"]] < shortest and self.ad.distance[self.ad.Q[i]["id"]] ~= -1 then
				shortest = self.ad.distance[self.ad.Q[i]["id"]];
				shortest_id = self.ad.Q[i]["id"];
			end;
		end;
		
		if shortest_id == -1 then
			self.ad.Q = {};
		else
			for i in pairs(self.ad.Q[shortest_id][setToUse]) do
				local inQ = false;
				for i2 in pairs(self.ad.Q) do
					if self.ad.Q[i2]["id"] ==  self.ad.Q[shortest_id][setToUse][i] then
						inQ = true;
					end;
				end;
				if inQ == true then
					--distanceupdate
					local alternative = shortest + 1 --self.ad.Q[shortest_id]["out_cost"][i];
					if alternative < self.ad.distance[self.ad.Q[shortest_id][setToUse][i]] or self.ad.distance[self.ad.Q[shortest_id][setToUse][i]] == -1 then
						--print("found shorter alternative for " .. Q[shortest_id][setToUse][i] .. " via " .. shortest_id .. " new distance: " .. alternative );
						self.ad.distance[self.ad.Q[shortest_id][setToUse][i]] = alternative;
						self.ad.pre[self.ad.Q[shortest_id][setToUse][i]] = shortest_id;
					end;
				end;			
			end;
			
			self.ad.Q[shortest_id] = nil;
		end;
		
	end;	
	--print("distance to 3: " .. self.ad.distance[3]);	
	
	for i in pairs(self.ad.pre) do
		--print("pre "..i .. " = ".. self.ad.pre[i]);
	end;
	
	--shortestPath(Graph,self.ad.distance,self.ad.pre,1,3);
	
	return self.ad;
	
end;

function AutoDrive:graphcopy(Graph)
	local Q = {};
	--print("Graphcopy");
	for i in pairs(Graph) do
		--print ("i = " .. i );
		local id = Graph[i]["id"];
		--print ("id = " .. id );
		local out = {};
		local incoming = {};
		local out_cost = {};
		local marker = {};
		
		--print ("out:");
		for i2 in pairs(Graph[i]["out"]) do
			out[i2] = Graph[i]["out"][i2];
			--print(""..i2 .. " : " .. out[i2]);
		end;
		--print("incoming");
		for i3 in pairs(Graph[i]["incoming"]) do
			incoming[i3] = Graph[i]["incoming"][i3];
		end;
		for i4 in pairs(Graph[i]["out_cost"]) do
			out_cost[i4] = Graph[i]["out_cost"][i4];
		end;
		
		
		for i5 in pairs(Graph[i]["marker"]) do
			marker[i5] = Graph[i]["marker"][i5];
		end;
		
		
		Q[i] = createNode(id,out,incoming,out_cost, marker);
		
		Q[i].x = Graph[i].x;
		Q[i].y = Graph[i].y;
		Q[i].z = Graph[i].z;
		
	end;

	return Q;
end;

function createNode(id,out,incoming,out_cost, marker)
	local p = {};
	p["id"] = id;
	p["out"] = out;
	p["incoming"] = incoming;
	p["out_cost"] = out_cost;
	p["marker"] = marker;
	--p["coords"] = coords;
	
	return p;
end

function AutoDrive:FastShortestPath(Graph,start,markerName, markerID)
	
	local wp = {};
	local count = 1;
	local id = start;
	--print("searching path for start id: " .. id .. " and target: " .. markerName .. " id: " .. markerID);
	while id ~= -1 and id ~= nil do
		
		wp[count] = Graph[id];
		count = count+1;
		--print(""..wp[count-1]["id"]);
		if id == markerID then
			id = nil;
		else
			id = g_currentMission.AutoDrive.mapWayPoints[id].marker[markerName];
		end;
	end;
	
	local wp_copy = AutoDrive:graphcopy(wp);
	
	--print("shortest path to " .. markerName);
	--for i in pairs(wp) do
		--print(""..wp[i]["id"]);
	--end;
	
	return wp_copy;
end;

function AutoDrive:shortestPath(Graph,distance,pre,start,endNode)
	local wp = {};
	local count = 1;
	local id = Graph[endNode]["id"];
	
	while self.ad.pre[id] ~= -1 do
		for i in pairs(Graph) do
			if Graph[i]["id"] == id then
				wp[count] = Graph[i];  --todo: maybe create copy
			end;
		end;
		count = count+1;
		id = self.ad.pre[id];
	end;

	
	local wp_reversed = {};
	for i in pairs(wp) do
		wp_reversed[count-i] = wp[i];
	end;
	
	local wp_copy = AutoDrive:graphcopy(wp_reversed);
	
	--print("shortest path to " .. Graph[endNode]["id"]);
	for i in pairs(wp) do
		--print(""..wp[i]["id"]);
	end;
	
	return wp_copy;
	
end;

function init(self)



	local aNameSearch = {"vehicle.name." .. g_languageShort, "vehicle.name.en", "vehicle.name", "vehicle.storeData.name", "vehicle#type"};
	self.bDisplay = 1; 
	if self.ad == nil then
		self.ad = {};
		
		
	end;
	
	self.bLongFormat = 0; 
	self.nSubStringLength = 40; 
	self.bDarkColor = 0; 
	self.nDebugOutput = 0; 
	self.bActive = false;
	self.bRoundTrip = false;
	self.bReverseTrack = false;
	self.bDrivingForward = true;
	self.nTargetX = 0;
	self.nTargetZ = 0;
	self.bInitialized = false;
	self.ad.wayPoints = {};
	self.bcreateMode = false;
	self.nCurrentWayPoint = 0;
	self.nlastLogged = 0;
	self.nloggingInterval = 500;
	self.logMessage = "";
	self.nPrintTime = 3000;
	self.ntargetSelected = -1;	
	self.nMapMarkerSelected = -1;
	self.sTargetSelected = "";
	if g_currentMission.AutoDrive ~= nil then
		if g_currentMission.AutoDrive.mapMarker[1] ~= nil then
			self.ntargetSelected = 1;
			self.nMapMarkerSelected = 1;
			self.sTargetSelected = g_currentMission.AutoDrive.mapMarker[1].name;
			local translation = AutoDrive:translate(sTargetSelected);
			sTargetSelected = translation;
		end;	
	end;
	self.bTargetMode = true;
	self.nSpeed = 40;
	self.bCreateMapPoints = false;
	self.bShowDebugMapMarker = false;
	self.nSelectedDebugPoint = -1;
	self.bShowSelectedDebugPoint = false;
	self.bChangeSelectedDebugPoint = false;
	self.DebugPointsIterated = {};
	self.bDeadLock = false;
	self.nTimeToDeadLock = 10000;
	self.bDeadLockRepairCounter = 4;
	
	self.bStopAD = false;
	self.bCreateMapMarker = false;
	self.bEnteringMapMarker = false;
	self.sEnteredMapMarkerString = "";
	
	if Steerable.load ~= nil then 
		local orgSteerableLoad = Steerable.load 
		Steerable.load = function(self,xmlFile) 
			orgSteerableLoad(self,xmlFile) 
			for nIndex,sXMLPath in pairs(aNameSearch) do 
				self.name = getXMLString(self.xmlFile, sXMLPath); 
				if self.name ~= nil then 
					break; 
				end; 
			end; 
			if self.name == nil then 
				self.name = g_i18n:getText("UNKNOWN")
			end; 
		end
	
	end;
	self.moduleInitialized = true;
	self.currentInput = "";

	self.requestWayPointTimer = 10000;

end;

function AutoDrive:translate(text)
	
	if text == "Hof" then
		return g_i18n:getText("AD_Hof");
	end;
	if text == "Kuhstall" then
		return g_i18n:getText("AD_Kuhstall");
	end;
	if text == "Schweinestall" then
		return g_i18n:getText("AD_Schweinestall");
	end;
	if text == "Schafsweide" then
		return g_i18n:getText("AD_Schafsweide");
	end;
	if text == "Tankstelle" then
		return g_i18n:getText("AD_Tankstelle");
	end;
	if text == "Viehhandel" then
		return g_i18n:getText("AD_Viehhandel");
	end;
	
	return text;
	
end;

function AutoDrive:newMouseEvent(superFunc,posX, posY, isDown, isUp, button)
	
	if g_currentMission.AutoDrive.showMouse then
		local x = InputBinding.mouseMovementX;
		local y = InputBinding.mouseMovementY;
		InputBinding.mouseMovementX = 0;
		InputBinding.mouseMovementY = 0;
		superFunc(self, posX, posY, isDown, isUp, button)
		InputBinding.mouseMovementX = x;
		InputBinding.mouseMovementY = y;
	else	
		superFunc(self, posX, posY, isDown, isUp, button)
	end;
end;

function AutoDrive:mouseEvent(posX, posY, isDown, isUp, button)
	if self == g_currentMission.controlledVehicle and AutoDrive.Hud.showHud == true then

		
		if g_currentMission.AutoDrive.showMouse and button == 1 and isDown then
			
			for _,button in pairs(AutoDrive.Hud.Buttons) do
				
				if posX > button.posX and posX < (button.posX + button.width) and posY > button.posY and posY < (button.posY + button.height) and button.isVisible then
					--print("Clicked button " .. button.name);
					AutoDrive:InputHandling(self, button.name);
				end;
				
			end;
		
		end;
	end;
	
	
end; 

function AutoDrive:keyEvent(unicode, sym, modifier, isDown) 
	
	if self == g_currentMission.controlledVehicle then
	
		--print("Unicode: " .. unicode .. " sym: " .. sym);
	
		if isDown and self.bEnteringMapMarker then 
			if sym == 13 then
				self.bEnteringMapMarker = false;
				self.isBroken = false;
			else
				if sym == 8 then
					self.sEnteredMapMarkerString = string.sub(self.sEnteredMapMarkerString,1,string.len(self.sEnteredMapMarkerString)-1)
				else
					if unicode ~= 0 then
						self.sEnteredMapMarkerString = self.sEnteredMapMarkerString .. string.char(unicode);
					end;
				end;
			end;
		end;
	
	end;
	
end; 

function AutoDrive:deactivate(self,stopVehicle)
				--[[
				if stopVehicle == true then
					local x,y,z = getWorldTranslation( self.components[1].node );
					local xl,yl,zl = worldToLocal(self.components[1].node, self.nTargetX,y,self.nTargetZ);
					AIVehicleUtil.driveToPoint(self, dt, 0, true, self.bDrivingForward, xl, zl, 0, false );
					self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF);
				end;
				--]]
				self.bActive = false; 
				self.forceIsActive = false;
				self.stopMotorOnLeave = true;
				self.disableCharacterOnLeave = true;
								
				self.bInitialized = false;
				self.nCurrentWayPoint = 0;
				self.bDrivingForward = true;
				if self.steeringEnabled == false then
					self.steeringEnabled = true;
				end
				self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF);

				--self.isControlled = false;
				
				--self.printMessage = g_i18n:getText("AD_Deactivated");
				--self.nPrintTime = 3000;
end;

function AutoDrive:update(dt)

	if self == g_currentMission.controlledVehicle then
		--self.printMessage = "Vehicle: " .. self.name;
		--self.nPrintTime = 3000;
		
		
		
		
		if InputBinding.hasEvent(InputBinding.ADSilomode) then
			
			--print("sending event to InputHandling");
			AutoDrive:InputHandling(self, "input_silomode");
		end;
		if InputBinding.hasEvent(InputBinding.ADRoundtrip) then
			AutoDrive:InputHandling(self, "input_roundtrip");			
		end; 
		
		if InputBinding.hasEvent(InputBinding.ADRecord) then
			AutoDrive:InputHandling(self, "input_record");
			
		end; 
		
		if InputBinding.hasEvent(InputBinding.ADEnDisable) then
			AutoDrive:InputHandling(self, "input_start_stop");
			
		end; 
		
		if InputBinding.hasEvent(InputBinding.ADSelectTarget) then
			AutoDrive:InputHandling(self, "input_nextTarget");
			
		end; 
		
		if InputBinding.hasEvent(InputBinding.ADSelectPreviousTarget) then
			AutoDrive:InputHandling(self, "input_previousTarget");
		end;
		
		if InputBinding.hasEvent(InputBinding.ADActivateDebug)  then 
			AutoDrive:InputHandling(self, "input_debug");			
		end; 
		
		if InputBinding.hasEvent(InputBinding.ADDebugShowClosest)  then 
			AutoDrive:InputHandling(self, "input_showNeighbor");
			
		end; 
		
		if InputBinding.hasEvent(InputBinding.ADDebugSelectNeighbor) then 
			AutoDrive:InputHandling(self, "input_showNeighbor");
			
		end; 
		if InputBinding.hasEvent(InputBinding.ADDebugCreateConnection) then 
			AutoDrive:InputHandling(self, "input_toggleConnection");
			
		end; 
		if InputBinding.hasEvent(InputBinding.ADDebugChangeNeighbor) then 
			AutoDrive:InputHandling(self, "input_nextNeighbor");
			
		end; 
		if InputBinding.hasEvent(InputBinding.ADDebugCreateMapMarker) then 
			AutoDrive:InputHandling(self, "input_createMapMarker");
			
		end; 
		
		if InputBinding.hasEvent(InputBinding.AD_Speed_up) then 
			AutoDrive:InputHandling(self, "input_increaseSpeed");
			
		end;
		
		if InputBinding.hasEvent(InputBinding.AD_Speed_down) then 
			AutoDrive:InputHandling(self, "input_decreaseSpeed");
			
		end;
		
		if InputBinding.hasEvent(InputBinding.ADToggleHud) then 
			AutoDrive:InputHandling(self, "input_toggleHud");
			
		end;
		if InputBinding.hasEvent(InputBinding.ADToggleMouse) then
			AutoDrive:InputHandling(self, "input_toggleMouse");

		end;
		if InputBinding.hasEvent(InputBinding.ADDebugDeleteWayPoint) then 
			AutoDrive:InputHandling(self, "input_removeWaypoint");
			
		end;
		
	end;

	if self.moduleInitialized == nil then
		init(self);
	end;

	if self.requestWayPointTimer >= 0 then
		self.requestWayPointTimer = self.requestWayPointTimer - dt;
	end;

	if g_currentMission.AutoDrive ~= nil then
		if g_currentMission.AutoDrive.requestedWaypoints ~= true and self.requestWayPointTimer < 0 and networkGetObjectId(self) ~= nil then
			AutoDriveMapEvent:sendEvent(self);
			g_currentMission.AutoDrive.requestedWaypoints = true;
		end;
	end;

	if self.currentInput ~= "" and self.isServer then
		--print("I am the server and start input handling. lets see if they think so too");
		AutoDrive:InputHandling(self, self.currentInput);
	end;

	if self.bActive == true and self.isServer then
		self.forceIsActive = true;
		self.stopMotorOnLeave = false;
		self.disableCharacterOnLeave = true;
		--self.isControlled = true;
		if self.isMotorStarted == false then
			self:startMotor();
		end;
		
		self.nTimeToDeadLock = self.nTimeToDeadLock - dt;
		if self.nTimeToDeadLock < 0 and self.nTimeToDeadLock ~= -1 then
			--print("Deadlock reached due to timer");
			self.bDeadLock = true;
		end;
		
	else
		self.bDeadLock = false;
		self.nTimeToDeadLock = 10000;
		self.bDeadLockRepairCounter = 4;
		--self.forceIsActive = false;
		--self.stopMotorOnLeave = true;
	end;
	
	if self.printMessage ~= nil then
		self.nPrintTime = self.nPrintTime - dt;
		if self.nPrintTime < 0 then
			self.nPrintTime = 3000;
			self.printMessage = nil;
		end;
	end;
	
	if self == g_currentMission.controlledVehicle then
		if AutoDrive.printMessage ~= nil then
			AutoDrive.nPrintTime = AutoDrive.nPrintTime - dt;
			if AutoDrive.nPrintTime < 0 then
				AutoDrive.nPrintTime = 3000;
				AutoDrive.printMessage = nil;
			end;
		end;
	end;
	
	--set target waypoint and create route
	--follow next waypoint until close enough (0.5m?), then select next waypoint
	--stop vehicle on arrival
	
	
	local veh = self;
	
	--follow waypoints on route:
	
	if self.bStopAD == true and self.isServer then
		AutoDrive:deactivate(self,false);
		self.bStopAD = false;
	end;
	
	if self.components ~= nil and self.isServer then
	
		local x,y,z = getWorldTranslation( self.components[1].node );
		local xl,yl,zl = worldToLocal(veh.components[1].node, x,y,z);
			
			if self.bActive == true then
				if self.steeringEnabled then
					self.steeringEnabled = false;
				end
				
				if self.bInitialized == false then
					self.nTimeToDeadLock = 10000;
					if self.bTargetMode == true then
						local closest = AutoDrive:findClosestWayPoint(veh);
						self.ad.wayPoints = AutoDrive:FastShortestPath(g_currentMission.AutoDrive.mapWayPoints, closest, g_currentMission.AutoDrive.mapMarker[self.nMapMarkerSelected].name, self.ntargetSelected);
						self.nCurrentWayPoint = 3;
					else
						self.nCurrentWayPoint = 1;
					end;
					
					if self.ad.wayPoints[self.nCurrentWayPoint] ~= nil then
						self.nTargetX = self.ad.wayPoints[self.nCurrentWayPoint].x;
						self.nTargetZ = self.ad.wayPoints[self.nCurrentWayPoint].z;
						self.bInitialized = true;
						self.bDrivingForward = true;
						
					else						
						--print("Autodrive hat ein Problem festgestellt");
						print("Autodrive hat ein Problem beim Initialisieren festgestellt");
						AutoDrive:deactivate(self,true);
					end;
				else
					if getDistance(x,z, self.nTargetX, self.nTargetZ) < 1.4 then
						
						self.nTimeToDeadLock = 10000;
						
						if self.ad.wayPoints[self.nCurrentWayPoint+1] ~= nil then
							self.nCurrentWayPoint = self.nCurrentWayPoint + 1;
							self.nTargetX = self.ad.wayPoints[self.nCurrentWayPoint].x;
							self.nTargetZ = self.ad.wayPoints[self.nCurrentWayPoint].z;
						else
							--print("Last waypoint reached");
							if self.bRoundTrip == false then
								--print("No Roundtrip");
								if self.bReverseTrack == true then
									--print("Starting reverse track");
									--reverse driving direction
									if self.bDrivingForward == true then
										self.bDrivingForward = false;
									else
										self.bDrivingForward = true;
									end;
									--reverse waypoints
									local reverseWaypoints = {};
									local _counterWayPoints = 0;
									for n in pairs(self.ad.wayPoints) do
										_counterWayPoints = _counterWayPoints + 1;
									end;
									for n in pairs(self.ad.wayPoints) do
										reverseWaypoints[_counterWayPoints] = self.ad.wayPoints[n];
										_counterWayPoints = _counterWayPoints - 1;
									end;
									for n in pairs(reverseWaypoints) do
										self.ad.wayPoints[n] = reverseWaypoints[n];
									end;
									--start again:
									self.nCurrentWayPoint = 1
									self.nTargetX = self.ad.wayPoints[self.nCurrentWayPoint].x;
									self.nTargetZ = self.ad.wayPoints[self.nCurrentWayPoint].z;
									
								else				
									--print("Shutting down");
									AutoDrive.printMessage = g_i18n:getText("AD_Driver_of") .. " " .. self.name .. " " .. g_i18n:getText("AD_has_reached") .. " " .. self.sTargetSelected;
									AutoDrive.nPrintTime = 6000;
									if self.isServer == true then
										xl,yl,zl = worldToLocal(veh.components[1].node, self.nTargetX,y,self.nTargetZ);
										
										AIVehicleUtil.driveToPoint(self, dt, 0, true, self.bDrivingForward, xl, zl, 0, false );
										
										veh:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF);
									end;
									
									veh:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF);
									
									AutoDrive:deactivate(self,true);
								end;
							else	
								--print("Going into next round");
								self.nCurrentWayPoint = 1
								if self.ad.wayPoints[self.nCurrentWayPoint] ~= nil then
									self.nTargetX = self.ad.wayPoints[self.nCurrentWayPoint].x;
									self.nTargetZ = self.ad.wayPoints[self.nCurrentWayPoint].z;
									
								else
									print("Autodrive hat ein Problem beim Rundkurs festgestellt");
									AutoDrive:deactivate(self,true);
								end;
							end;
						end;
					end;
						
				end;
				
				
				if self.bActive == true then
					if self.isServer == true then
						if self.ad.wayPoints[self.nCurrentWayPoint+1] ~= nil then
							--AutoDrive:addlog("Issuing Drive Request");
							xl,yl,zl = worldToLocal(veh.components[1].node, self.nTargetX,y,self.nTargetZ);

							local speed_override = -1;
							if self.ad.wayPoints[self.nCurrentWayPoint-1] ~= nil and self.ad.wayPoints[self.nCurrentWayPoint+1] ~= nil then
								local wp_ahead = self.ad.wayPoints[self.nCurrentWayPoint+1];
								local wp_current = self.ad.wayPoints[self.nCurrentWayPoint];
								local wp_ref = self.ad.wayPoints[self.nCurrentWayPoint-1];
								local angle = AutoDrive:angleBetween( 	{x=	wp_ahead.x	-	wp_ref.x, z = wp_ahead.z - wp_ref.z },
																		{x=	wp_current.x-	wp_ref.x, z = wp_current.z - wp_ref.z } )


								if angle < 3 then speed_override = -1; end;
								if angle >= 3 and angle < 5 then speed_override = 35; end;
								if angle >= 5 and angle < 8 then speed_override = 30; end;
								if angle >= 8 and angle < 12 then speed_override = 25; end;
								if angle >= 12 and angle < 15 then speed_override = 15; end;
								if angle >= 15 and angle < 50 then speed_override = 5; end;

								--print("Angle: " .. angle .. " speed: " .. speed_override);

							end;
							if speed_override == -1 then speed_override = self.nSpeed; end;

							AIVehicleUtil.driveToPoint(self, dt, 1, true, self.bDrivingForward, xl, zl, speed_override, false );
						else
							--print("Reaching last waypoint - slowing down");
							xl,yl,zl = worldToLocal(veh.components[1].node, self.nTargetX,y,self.nTargetZ);
							AIVehicleUtil.driveToPoint(self, dt, 1, true, self.bDrivingForward, xl, zl, 5, false );
						end;
					end;
				end;
			end;
		
		veh.aiSteeringSpeed = 0.4;
		--print(" target: " .. self.nTargetX .. "/" .. self.nTargetZ .. " steeringSpeed: " .. veh.aiSteeringSpeed);
	end;
	
	if self.bDeadLock == true and self.bActive == true and self.isServer then
		AutoDrive.printMessage = g_i18n:getText("AD_Driver_of") .. " " .. self.name .. " " .. g_i18n:getText("AD_got_stuck");
		AutoDrive.nPrintTime = 10000;
		
		--deadlock handling
		if self.bDeadLockRepairCounter < 1 then
			AutoDrive.printMessage = g_i18n:getText("AD_Driver_of") .. " " .. self.name .. " " .. g_i18n:getText("AD_got_stuck");
			AutoDrive.nPrintTime = 10000;
			self.bStopAD = true;
			self.bActive = false;
		else
			--print("AD: Trying to recover from deadlock")
			if self.ad.wayPoints[self.nCurrentWayPoint+2] ~= nil then
				self.nCurrentWayPoint = self.nCurrentWayPoint + 1;
				self.nTargetX = self.ad.wayPoints[self.nCurrentWayPoint].x;
				self.nTargetZ = self.ad.wayPoints[self.nCurrentWayPoint].z;

				self.bDeadLock = false;
				self.nTimeToDeadLock = 10000;
				self.bDeadLockRepairCounter = self.bDeadLockRepairCounter - 1;
			end;
		end;
	end;
	
	if veh == g_currentMission.controlledVehicle then
		if veh ~= nil then
			--manually create waypoints in create-mode:
			if self.bcreateMode == true then
				--record waypoints every 6m
				local i = 0;
				for n in pairs(self.ad.wayPoints) do 
					i = i+1;
				end;
				i = i+1;
				
				--first entry
				if i == 1 then
					local x1,y1,z1 = getWorldTranslation(veh.components[1].node);
					self.ad.wayPoints[i] = createVector(x1,y1,z1);
					
					if self.bCreateMapPoints == true then
						AutoDrive:MarkChanged();
						g_currentMission.AutoDrive.mapWayPointsCounter = g_currentMission.AutoDrive.mapWayPointsCounter + 1;
						g_currentMission.AutoDrive.mapWayPoints[g_currentMission.AutoDrive.mapWayPointsCounter] = createNode(g_currentMission.AutoDrive.mapWayPointsCounter,{},{},{},{});
						g_currentMission.AutoDrive.mapWayPoints[g_currentMission.AutoDrive.mapWayPointsCounter].x = x1;
						g_currentMission.AutoDrive.mapWayPoints[g_currentMission.AutoDrive.mapWayPointsCounter].y = y1;
						g_currentMission.AutoDrive.mapWayPoints[g_currentMission.AutoDrive.mapWayPointsCounter].z = z1;
						
						--print("Creating Waypoint #" .. g_currentMission.AutoDrive.mapWayPointsCounter);
							
					end;
					
					i = i+1;
				else
					if i == 2 then
						local x,y,z = getWorldTranslation(veh.components[1].node);
						local wp = self.ad.wayPoints[i-1];
						if getDistance(x,z,wp.x,wp.z) > 3 then
							self.ad.wayPoints[i] = createVector(x,y,z);
							if self.bCreateMapPoints == true then
								g_currentMission.AutoDrive.mapWayPointsCounter = g_currentMission.AutoDrive.mapWayPointsCounter + 1;
								--edit previous point
								g_currentMission.AutoDrive.mapWayPoints[g_currentMission.AutoDrive.mapWayPointsCounter-1].out[1] = g_currentMission.AutoDrive.mapWayPointsCounter;
								g_currentMission.AutoDrive.mapWayPoints[g_currentMission.AutoDrive.mapWayPointsCounter-1].out_cost[1] = 1;
								--edit current point
								--print("Creating Waypoint #" .. g_currentMission.AutoDrive.mapWayPointsCounter);
								g_currentMission.AutoDrive.mapWayPoints[g_currentMission.AutoDrive.mapWayPointsCounter] = createNode(g_currentMission.AutoDrive.mapWayPointsCounter,{},{},{},{});
								g_currentMission.AutoDrive.mapWayPoints[g_currentMission.AutoDrive.mapWayPointsCounter].incoming[1] = g_currentMission.AutoDrive.mapWayPointsCounter-1;
								g_currentMission.AutoDrive.mapWayPoints[g_currentMission.AutoDrive.mapWayPointsCounter].x = x;
								g_currentMission.AutoDrive.mapWayPoints[g_currentMission.AutoDrive.mapWayPointsCounter].y = y;
								g_currentMission.AutoDrive.mapWayPoints[g_currentMission.AutoDrive.mapWayPointsCounter].z = z;
							end;

							i = i+1;
						end;
					else
						local x,y,z = getWorldTranslation(veh.components[1].node);
						local wp = self.ad.wayPoints[i-1];
						local wp_ref = self.ad.wayPoints[i-2]
						local angle = AutoDrive:angleBetween( {x=x-wp_ref.x,z=z-wp_ref.z},{x=wp.x-wp_ref.x, z = wp.z - wp_ref.z } )
						--print("Angle between: " .. angle );
						local max_distance = 6;
						if angle < 3 then max_distance = 20; end;
						if angle >= 3 and angle < 5 then max_distance = 6; end;
						if angle >= 5 and angle < 8 then max_distance = 4; end;
						if angle >= 8 and angle < 12 then max_distance = 2; end;
						if angle >= 12 and angle < 15 then max_distance = 1; end;
						if angle >= 15 and angle < 50 then max_distance = 0.5; end;

						if getDistance(x,z,wp.x,wp.z) > max_distance then
							self.ad.wayPoints[i] = createVector(x,y,z);
							if self.bCreateMapPoints == true then
								g_currentMission.AutoDrive.mapWayPointsCounter = g_currentMission.AutoDrive.mapWayPointsCounter + 1;
								--edit previous point
								g_currentMission.AutoDrive.mapWayPoints[g_currentMission.AutoDrive.mapWayPointsCounter-1].out[1] = g_currentMission.AutoDrive.mapWayPointsCounter;
								g_currentMission.AutoDrive.mapWayPoints[g_currentMission.AutoDrive.mapWayPointsCounter-1].out_cost[1] = 1;
								--edit current point
								--print("Creating Waypoint #" .. g_currentMission.AutoDrive.mapWayPointsCounter);
								g_currentMission.AutoDrive.mapWayPoints[g_currentMission.AutoDrive.mapWayPointsCounter] = createNode(g_currentMission.AutoDrive.mapWayPointsCounter,{},{},{},{});
								g_currentMission.AutoDrive.mapWayPoints[g_currentMission.AutoDrive.mapWayPointsCounter].incoming[1] = g_currentMission.AutoDrive.mapWayPointsCounter-1;
								g_currentMission.AutoDrive.mapWayPoints[g_currentMission.AutoDrive.mapWayPointsCounter].x = x;
								g_currentMission.AutoDrive.mapWayPoints[g_currentMission.AutoDrive.mapWayPointsCounter].y = y;
								g_currentMission.AutoDrive.mapWayPoints[g_currentMission.AutoDrive.mapWayPointsCounter].z = z;
							end;

							i = i+1;
						end;
					end;

				end;

			end;
		end;	
	end;

	--[[trigger test

	--get trailer:
	local trailer = nil;
	if self.attachedImplements ~= nil then
		for _, implement in pairs(self.attachedImplements) do
			if implement.object ~= nil then
				if implement.object.getCapacity ~= nil then
					if implement.object.readCapacity ~= true then
						--print("capacity = " .. implement.object:getCapacity());
						implement.object.readCapacity = true;
					end;

					trailer = implement.object;
				else
					if implement.object.addebug ~= true then
						--print("implement has no capacity");
						implement.object.addebug = true;
					end;
				end;
			end;
		end;

		--check trailer trigger: trailerTipTriggers
		if trailer ~= nil then

			if g_currentMission.trailerInTipRange ~= nil then
					--print("Found trigger: ");
					--activate trigger:
					if g_currentMission.trailerInTipRange.tipping ~= true then
						print("toggling tp state");
						g_currentMission.trailerInTipRange:toggleTipState(g_currentMission.currentTipTrigger, g_currentMission.currentTipReferencePointIndex);
						--trailer:toggleTipState(trailer.trailerTipTriggers[1],trailer.tipReferencePoints[trailer.preferedTipReferencePointIndex]);
						g_currentMission.trailerInTipRange.tipping = true;
					end;
			end;
		end;

	end;
	--]]
	--triger test end
	
	if self.isServer == true then
		AutoDriveInputEvent:sendEvent(self);
		--print("Sending Event as server");
	end;
	
	--AutoDrive:log(dt);
end;

function AutoDrive:updateButtons(vehicle)

	for _,button in pairs(AutoDrive.Hud.Buttons) do
		if button.name == "input_silomode" then
			local buttonImg = "";
			if vehicle.bReverseTrack == true then
				button.img_active = button.img_on;						
			else
				button.img_active = button.img_off;
			end;
			
			button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);					
		end;
	
		if button.name == "input_record" then
			local buttonImg = "";
			if vehicle.bcreateMode == true then
				button.img_active = button.img_on;						
			else
				button.img_active = button.img_off;
			end;
			button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
		end;
		
		if button.name == "input_start_stop" then
			local buttonImg = "";
			if vehicle.bActive == true then
				button.img_active = button.img_on;						
			else
				button.img_active = button.img_off;
			end;
			button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
		end;		
		
		if button.name == "input_debug" then
			local buttonImg = "";
			if vehicle.bCreateMapPoints == true then
				button.img_active = button.img_on;						
			else
				button.img_active = button.img_off;
			end;
			button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
		end;	
		
		
		if button.name == "input_showClosest" then
			local buttonImg = "";
			if vehicle.bShowDebugMapMarker == true then
				button.img_active = button.img_on;						
			else
				button.img_active = button.img_off;
			end;
			button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
		end;
		
		if button.name == "input_showNeighbor" then
			local buttonImg = "";
			if vehicle.bShowSelectedDebugPoint == true then
				button.img_active = button.img_on;						
			else
				button.img_active = button.img_off;
			end;
			button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
		end;
		
		if button.name == "input_recalculate" then
			local buttonImg = "";
			if AutoDrive:GetChanged() == true then
				button.img_active = button.img_on;		
				button.isVisible = true;
			else
				button.img_active = button.img_off;
				button.isVisible = false;
			end;
			button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
		end;
		
		if button.name == "input_removeWaypoint" then
			local buttonImg = "";
			if AutoDrive:GetChanged() == true then
				button.img_active = button.img_on;		
				button.isVisible = true;
			else
				button.img_active = button.img_off;
				button.isVisible = false;
			end;
			button.ov = Overlay:new(nil, button.img_active,button.posX ,button.posY , AutoDrive.Hud.buttonWidth, AutoDrive.Hud.buttonHeight);
		end;
		
	end;

end;

function AutoDrive:log(dt)
	
	self.nlastLogged = self.nlastLogged + dt;
	if self.nlastLogged >= self.nloggingInterval then
		self.nlastLogged = self.nlastLogged - self.nloggingInterval;
		if self.logMessage ~= "" then
			print(self.logMessage);
			self.logMessage = "";
		end;
	end;
	
end;

function AutoDrive:addlog(text)
	--[[
	if string.find(self.logMessage, text) == nil then
		self.logMessage = self.logMessage .. text .. "\n";
	end;
	--]]
	self.logMessage = text;
end;

function createVector(x,y,z)
	local table t = {};
	t["x"] = x;
	t["y"] = y;
	t["z"] = z;
	return t; 
end;

function getDistance(x1,z1,x2,z2)
	return math.sqrt((x1-x2)*(x1-x2) + (z1-z2)*(z1-z2) );
end;

function readWayPoints()
	--read xmlFile
	--unique for each map
	--waypoints are ordered in a bidirectional graph
end;

function findWay(startWayPointID, targetWayPointID)
	--graph algorithm to find shortest path towards target
	--return list of waypoints
end;

function AutoDrive:findClosestWayPoint(veh)
	--returns waypoint closest to vehicle position
	local x1,y1,z1 = getWorldTranslation(veh.components[1].node);
	
	local closest = 1;
	local distance = getDistance(g_currentMission.AutoDrive.mapWayPoints[1].x,g_currentMission.AutoDrive.mapWayPoints[1].z,x1,z1);
	for i in pairs(g_currentMission.AutoDrive.mapWayPoints) do
		local dis = getDistance(g_currentMission.AutoDrive.mapWayPoints[i].x,g_currentMission.AutoDrive.mapWayPoints[i].z,x1,z1);
		if dis < distance then
			closest = i;
			distance = dis;
		end;
	end;
	
	return closest;
end;


function AutoDrive:draw()

	if self.moduleInitialized == true then
		if self.nCurrentWayPoint > 0 then
			if self.ad.wayPoints[self.nCurrentWayPoint+1] ~= nil then
				--print("drawing debug line");
				drawDebugLine(self.ad.wayPoints[self.nCurrentWayPoint].x, self.ad.wayPoints[self.nCurrentWayPoint].y+4, self.ad.wayPoints[self.nCurrentWayPoint].z, 0,1,1, self.ad.wayPoints[self.nCurrentWayPoint+1].x, self.ad.wayPoints[self.nCurrentWayPoint+1].y+4, self.ad.wayPoints[self.nCurrentWayPoint+1].z, 1,1,1);
			end;
			if self.ad.wayPoints[self.nCurrentWayPoint-1] ~= nil then
				drawDebugLine(self.ad.wayPoints[self.nCurrentWayPoint-1].x, self.ad.wayPoints[self.nCurrentWayPoint-1].y+4, self.ad.wayPoints[self.nCurrentWayPoint-1].z, 0,1,1, self.ad.wayPoints[self.nCurrentWayPoint].x, self.ad.wayPoints[self.nCurrentWayPoint].y+4, self.ad.wayPoints[self.nCurrentWayPoint].z, 1,1,1);

			end;
		end;
		if self.bcreateMode == true then
			local _drawCounter = 1;
			for n in pairs(self.ad.wayPoints) do
				if self.ad.wayPoints[n+1] ~= nil then
					drawDebugLine(self.ad.wayPoints[n].x, self.ad.wayPoints[n].y+4, self.ad.wayPoints[n].z, 0,1,1, self.ad.wayPoints[n+1].x, self.ad.wayPoints[n+1].y+4, self.ad.wayPoints[n+1].z, 1,1,1);
				else
					drawDebugLine(self.ad.wayPoints[n].x, self.ad.wayPoints[n].y+4, self.ad.wayPoints[n].z, 0,1,1, self.ad.wayPoints[n].x, self.ad.wayPoints[n].y+5, self.ad.wayPoints[n].z, 1,1,1);
				end;
			end;
		end;

		if self.bCreateMapPoints == true then
			if self == g_currentMission.controlledVehicle then
				for i,point in pairs(g_currentMission.AutoDrive.mapWayPoints) do
					local x1,y1,z1 = getWorldTranslation(self.components[1].node);
					local distance = getDistance(point.x,point.z,x1,z1);
					if distance < 50 then

						if point.out ~= nil then
							for i2,neighbor in pairs(point.out) do
								drawDebugLine(point.x, point.y+4, point.z, 0,1,1, g_currentMission.AutoDrive.mapWayPoints[neighbor].x, g_currentMission.AutoDrive.mapWayPoints[neighbor].y+4, g_currentMission.AutoDrive.mapWayPoints[neighbor].z, 1,1,1);
							end;
						end;

					end;
				end;

				if self.bShowDebugMapMarker == true then
					local closest = AutoDrive:findClosestWayPoint(self);
					local x1,y1,z1 = getWorldTranslation(self.components[1].node);
					drawDebugLine(x1, y1, z1, 1,1,1, g_currentMission.AutoDrive.mapWayPoints[closest].x, g_currentMission.AutoDrive.mapWayPoints[closest].y+4, g_currentMission.AutoDrive.mapWayPoints[closest].z, 1,1,1);

					if self.printMessage == nil or string.find(self.printMessage, g_i18n:getText("AD_Debug_closest")) ~= nil then
						self.printMessage = g_i18n:getText("AD_Debug_closest") .. closest;
						self.nPrintTime = 6000;
					end;

					if self.bCreateMapMarker == true and self.bEnteringMapMarker == false then

						g_currentMission.AutoDrive.mapMarkerCounter = g_currentMission.AutoDrive.mapMarkerCounter + 1;
						g_currentMission.AutoDrive.mapMarker[g_currentMission.AutoDrive.mapMarkerCounter] = {id=closest, name= self.sEnteredMapMarkerString};
						self.bCreateMapMarker = false;
						self.printMessage = g_i18n:getText("AD_Debug_waypoint_created_1") .. closest .. g_i18n:getText("AD_Debug_waypoint_created_2");
						self.nPrintTime = 30000;
						AutoDrive:MarkChanged();
						g_currentMission.isPlayerFrozen = false;
						self.isBroken = false;
						--g_currentMission.controlPlayer = true;


					end;


					if self.bShowSelectedDebugPoint == true then
						if self.DebugPointsIterated[self.nSelectedDebugPoint] ~= nil then

							drawDebugLine(x1, y1, z1, 1,1,1, self.DebugPointsIterated[self.nSelectedDebugPoint].x, self.DebugPointsIterated[self.nSelectedDebugPoint].y+4, self.DebugPointsIterated[self.nSelectedDebugPoint].z, 1,1,1);
						else
							self.nSelectedDebugPoint = 1;
						end;

						if self.bChangeSelectedDebugPoint == true then

							local out_counter = 1;
							local exists = false;
							for i in pairs(g_currentMission.AutoDrive.mapWayPoints[closest].out) do
								if exists == true then
									--print ("Entry exists "..i.. " out_counter: "..out_counter);
									g_currentMission.AutoDrive.mapWayPoints[closest].out[out_counter] = g_currentMission.AutoDrive.mapWayPoints[closest].out[i];
									g_currentMission.AutoDrive.mapWayPoints[closest].out_cost[out_counter] = g_currentMission.AutoDrive.mapWayPoints[closest].out_cost[i];
									out_counter = out_counter +1;
								else
									if g_currentMission.AutoDrive.mapWayPoints[closest].out[i] == self.DebugPointsIterated[self.nSelectedDebugPoint].id then

										AutoDrive:MarkChanged()
										g_currentMission.AutoDrive.mapWayPoints[closest].out[i] = nil;
										g_currentMission.AutoDrive.mapWayPoints[closest].out_cost[i] = nil;

										if g_currentMission.autoLoadedMap ~= nil and g_currentMission.AutoDrive.adXml ~= nil then
											removeXMLProperty(g_currentMission.AutoDrive.adXml, "AutoDrive." .. g_currentMission.autoLoadedMap .. ".waypoints.wp".. closest ..".out" .. i) ;
											removeXMLProperty(g_currentMission.AutoDrive.adXml, "AutoDrive." .. g_currentMission.autoLoadedMap .. ".waypoints.wp".. closest ..".out_cost" .. i) ;
										end;

										local incomingExists = false;
										for _,i2 in pairs(g_currentMission.AutoDrive.mapWayPoints[self.nSelectedDebugPoint].incoming) do
											if i2 == closest or incomingExists then
												incomingExists = true;
												if g_currentMission.AutoDrive.mapWayPoints[self.nSelectedDebugPoint].incoming[_ + 1] ~= nil then
													g_currentMission.AutoDrive.mapWayPoints[self.nSelectedDebugPoint].incoming[_] = g_currentMission.AutoDrive.mapWayPoints[self.nSelectedDebugPoint].incoming[_ + 1];
													g_currentMission.AutoDrive.mapWayPoints[self.nSelectedDebugPoint].incoming[_ + 1] = nil;
												else
													g_currentMission.AutoDrive.mapWayPoints[self.nSelectedDebugPoint].incoming[_] = nil;
												end;
											end;
										end;

										exists = true;
									else
										out_counter = out_counter +1;
									end;
								end;
							end;

							if exists == false then
								g_currentMission.AutoDrive.mapWayPoints[closest].out[out_counter] = self.DebugPointsIterated[self.nSelectedDebugPoint].id;
								g_currentMission.AutoDrive.mapWayPoints[closest].out_cost[out_counter] = 1;

								local incomingCounter = 1;
								for _,id in pairs(self.DebugPointsIterated[self.nSelectedDebugPoint].incoming) do
									incomingCounter = incomingCounter + 1;
								end;
								self.DebugPointsIterated[self.nSelectedDebugPoint].incoming[incomingCounter] = g_currentMission.AutoDrive.mapWayPoints[closest].id;

								AutoDrive:MarkChanged()
							end;


							self.bChangeSelectedDebugPoint = false;

						end;

						if self.bChangeSelectedDebugPointSelection == true then
							self.nSelectedDebugPoint = self.nSelectedDebugPoint + 1;
							self.bChangeSelectedDebugPointSelection = false;
						end;
					end;
				end;
			end;
		end;


		if self == g_currentMission.controlledVehicle then

			if AutoDrive.printMessage ~= nil then
				local adFontSize = 0.014;
				local adPosX = 0.03 + g_currentMission.helpBoxWidth
				local adPosY = 0.975;
				renderText(adPosX, adPosY, adFontSize, AutoDrive.printMessage);
				--self.printMessage = nil;
			end;

			if self.printMessage ~= nil and AutoDrive.printMessage == nil then
				local adFontSize = 0.014;
				local adPosX = 0.03 + g_currentMission.helpBoxWidth
				local adPosY = 0.975;
				renderText(adPosX, adPosY, adFontSize, self.printMessage);
				--self.printMessage = nil;
			end;
		end;

		if AutoDrive.Hud ~= nil then
			if AutoDrive.Hud.showHud == true then
				AutoDrive:drawHud(self);
			end;
		end;
	end;
end; 

function AutoDrive:drawHud(vehicle)
		
	if vehicle == g_currentMission.controlledVehicle then
		AutoDrive:updateButtons(vehicle);
		
		local posX = 0.82;
		local posY = 0.15;
		local width = 0.16;
		local height = 0.10;
		local borderX = 0.008;
		local borderY = 0.005;
		
		local buttonWidth = 0.04;
		local buttonHeight = 0.04;
		
		local ovWidth = AutoDrive.Hud.Background.width;
		local ovHeight = AutoDrive.Hud.Background.height;
		if vehicle.bEnteringMapMarker == true then
			ovHeight = ovHeight + 0.08;
		end;
		
		local buttonCounter = 0;
		for _,button in pairs(AutoDrive.Hud.Buttons) do
			if button.isVisible then
				buttonCounter = buttonCounter + 1;
			end;
		end;
		
		AutoDrive.Hud.rowCurrent = math.ceil(buttonCounter / AutoDrive.Hud.cols);	
		
		ovHeight = ovHeight + (AutoDrive.Hud.rowCurrent-2) * 0.05;
	

		AutoDrive.Hud.Background.ov = Overlay:new(nil, AutoDrive.Hud.Background.img, AutoDrive.Hud.Background.posX, AutoDrive.Hud.Background.posY , ovWidth, ovHeight);
		AutoDrive.Hud.Background.ov:render();
		
		
		for _,button in pairs(AutoDrive.Hud.Buttons) do
			if button.isVisible then
				button.ov:render();
			end;
		end;
		
		
		
		
		
		if vehicle.sTargetSelected ~= nil then
			
		
			local adFontSize = 0.014;
			local adPosX = AutoDrive.Hud.posX + 0.005 + AutoDrive.Hud.borderX; --0.03 + g_currentMission.helpBoxWidth
			local adPosY = AutoDrive.Hud.posY + 0.005 + (AutoDrive.Hud.borderY + AutoDrive.Hud.buttonHeight) * AutoDrive.Hud.rowCurrent; --+ 0.003; --0.975;
			setTextColor(1,1,1,1);
			renderText(adPosX, adPosY, adFontSize, vehicle.sTargetSelected);
			renderText(AutoDrive.Hud.posX - 0.02 + AutoDrive.Hud.width, adPosY, adFontSize, "" .. vehicle.nSpeed);
			
			--[[
			local img1 = Utils.getNoNil("img/createMapMarker.dds", "empty.dds" )
			local state, result = pcall( Utils.getFilename, img1, AutoDrive.directory )
			if not state then
				print("ERROR: "..tostring(result).." (img1: "..tostring(img1)..")")
				return
			end
			local target_ov = Overlay:new(nil, result, adPosX, adPosY , 0.01, 0.01* (g_screenWidth / g_screenHeight));
			target_ov:render();
			--]]
		end;

		if vehicle.bEnteringMapMarker == true then
			local adFontSize = 0.014;
			local adPosX = AutoDrive.Hud.posX + 0.005 + AutoDrive.Hud.borderX; --0.03 + g_currentMission.helpBoxWidth
			local adPosY = AutoDrive.Hud.posY + 0.005 + 0.03 + (AutoDrive.Hud.borderY + AutoDrive.Hud.buttonHeight) * AutoDrive.Hud.rowCurrent; --+ 0.003; --0.975;
			setTextColor(1,1,1,1);
			renderText(adPosX, adPosY + 0.03, adFontSize, g_i18n:getText("AD_new_marker_helptext"));
			renderText(adPosX, adPosY, adFontSize, g_i18n:getText("AD_new_marker") .. " " .. vehicle.sEnteredMapMarkerString);
		end;

		
		end;
	
end;

function AutoDrive:removeMapWayPoint(del)
		AutoDrive:MarkChanged();
		
		--remove node on all out going nodes
		for _,node in pairs(del.out) do			
			local IncomingCounter = 1;
			local deleted = false;
			for __,incoming in pairs(g_currentMission.AutoDrive.mapWayPoints[node].incoming) do
				if incoming == del.id then
					deleted = true
				end				
				if deleted then
					if g_currentMission.AutoDrive.mapWayPoints[node].incoming[__ + 1] ~= nil then
						g_currentMission.AutoDrive.mapWayPoints[node].incoming[__] = g_currentMission.AutoDrive.mapWayPoints[node].incoming[__ + 1];
						--g_currentMission.AutoDrive.mapWayPoints[node].incoming[__ + 1] = nil;
					else
						g_currentMission.AutoDrive.mapWayPoints[node].incoming[__] = nil;
					end;
				end;
								
			end;			
		end;
		
		--remove node on all incoming nodes
		
		for _,node in pairs(g_currentMission.AutoDrive.mapWayPoints) do
			
			local deleted = false;
			for __,out_id in pairs(node.out) do
				if out_id == del.id then
					deleted = true;
				end;
				
				
				if deleted then
					if node.out[__ + 1 ] ~= nil then
						node.out[__] = node.out[__+1];
						node.out_cost[__] = node.out_cost[__+1];
					else
						node.out[__] = nil;
						node.out_cost[__] = nil;
					end;
				end;
			end;
			
		end;
		
		--adjust ids for all succesive nodes :(
		
		local deleted = true;
		for _,node in pairs(g_currentMission.AutoDrive.mapWayPoints) do
			if _ > del.id then
				local oldID = node.id;				
				--adjust all possible references in nodes that have a connection with this node
				
				for __,innerNode in pairs(g_currentMission.AutoDrive.mapWayPoints) do
					for ___,innerNodeOutID in pairs(innerNode.out) do
						if innerNodeOutID == oldID then
							innerNode.out[___] = oldID - 1;
						end;
					end;
				end;

				for __,outGoingID in pairs(node.out) do
					for ___,innerNodeIncoming in pairs(g_currentMission.AutoDrive.mapWayPoints[outGoingID].incoming) do
						if innerNodeIncoming == oldID then
							g_currentMission.AutoDrive.mapWayPoints[outGoingID].incoming[___] = oldID - 1;
						end;
					end;
				end;
				
				g_currentMission.AutoDrive.mapWayPoints[_ - 1] = node;
				node.id = node.id - 1;
				
				if g_currentMission.AutoDrive.mapWayPoints[_ + 1] == nil then
					g_currentMission.AutoDrive.mapWayPoints[_] = nil;
					g_currentMission.AutoDrive.mapWayPointsCounter = g_currentMission.AutoDrive.mapWayPointsCounter - 1;
				end;
				
			end;
		end;
		
		--adjust all mapmarkers
		local deletedMarker = false;
		for _,marker in pairs(g_currentMission.AutoDrive.mapMarker) do
			if marker.id == del.id then
				deletedMarker = true;
			end;
			if deletedMarker then
				if g_currentMission.AutoDrive.mapMarker[_+1] ~= nil then
					g_currentMission.AutoDrive.mapMarker[_] =  g_currentMission.AutoDrive.mapMarker[_+1];
				else
					g_currentMission.AutoDrive.mapMarker[_] = nil;
				end;
			end;
			if marker.id > del.id then
				marker.id = marker.id -1;
			end;
		end;

end;

function getFillType_new(fillType, implementTypeName)
	local sFillType = g_i18n:getText("UNKNOWN"); 
	
	if FillUtil.fillTypeIndexToDesc[fillType] ~= nil then
		output1 =  FillUtil.fillTypeIndexToDesc[fillType].nameI18N
		if string.find(output1, "Missing") then
			sFillType = g_i18n:getText("UNKNOWN"); 
		else
			sFillType = output1;
		end;
	end;
	
	return sFillType;
end; 

function round(num, idp) 
	if Utils.getNoNil(num, 0) > 0 then 
		local mult = 10^(idp or 0); 
		return math.floor(num * mult + 0.5) / mult; 
	else 
		return 0; 
	end; 
end; 

function getPercentage(capacity, level) 
	return level / capacity * 100; 
end;

function AutoDrive:angleBetween(vec1, vec2)

	local scalarproduct_top = vec1.x * vec2.x + vec1.z * vec2.z;
	local scalarproduct_down = math.sqrt(vec1.x * vec1.x + vec1.z*vec1.z) * math.sqrt(vec2.x * vec2.x + vec2.z*vec2.z)
	local scalarproduct = scalarproduct_top / scalarproduct_down;

	return math.deg(math.acos(scalarproduct));
end
 
addModEventListener(AutoDrive);

--InputEvent%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--InputEvent%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--InputEvent%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


AutoDriveInputEvent = {};
AutoDriveInputEvent_mt = Class(AutoDriveInputEvent, Event);

InitEventClass(AutoDriveInputEvent, "AutoDriveInputEvent");

function AutoDriveInputEvent:emptyNew()
    local self = Event:new(AutoDriveInputEvent_mt);
    self.className="AutoDriveInputEvent";
    return self;
end;

function AutoDriveInputEvent:new(vehicle)
    local self = AutoDriveInputEvent:emptyNew()
    self.vehicle = vehicle;
	
	self.bActive = vehicle.bActive;
	self.bRoundTrip = vehicle.bRoundTrip;
	self.bReverseTrack = vehicle.bReverseTrack;
	self.bDrivingForward = vehicle.bDrivingForward;
	self.nTargetX = vehicle.nTargetX;
	self.nTargetZ = vehicle.nTargetZ;
	self.bInitialized = vehicle.bInitialized;
	self.wayPoints = vehicle.ad.wayPoints;
	self.bcreateMode = vehicle.bcreateMode;
	self.nCurrentWayPoint = vehicle.nCurrentWayPoint;
	self.nlastLogged = vehicle.nlastLogged;
	self.nloggingInterval = vehicle.nloggingInterval;
	self.logMessage = vehicle.logMessage;
	self.nPrintTime = vehicle.nPrintTime;
	self.ntargetSelected = vehicle.ntargetSelected;
	self.bTargetMode = vehicle.bTargetMode;
	self.nMapMarkerSelected = vehicle.nMapMarkerSelected;
	self.nSpeed = vehicle.nSpeed;
	self.bCreateMapPoints = vehicle.bCreateMapPoints;
	self.bShowDebugMapMarker = vehicle.bShowDebugMapMarker;
	self.nSelectedDebugPoint = vehicle.nSelectedDebugPoint;
	self.bShowSelectedDebugPoint = vehicle.bShowSelectedDebugPoint;
	self.bChangeSelectedDebugPoint = vehicle.bChangeSelectedDebugPoint;
	self.DebugPointsIterated = vehicle.DebugPointsIterated;
	self.sTargetSelected = vehicle.sTargetSelected;
	self.bStopAD = vehicle.bStopAD;
	self.bforceIsActive = vehicle.forceIsActive;
	self.bStopMotorOnLeave = vehicle.stopMotorOnLeave;

	self.bDeadLock = vehicle.bDeadLock; --new
	self.nTimeToDeadLock = vehicle.nTimeToDeadLock;
	self.bDeadLockRepairCounter = vehicle.bDeadLockRepairCounter;
	self.bCreateMapMarker =  vehicle.bCreateMapMarker;
	self.bEnteringMapMarker =  vehicle.bEnteringMapMarker;
	self.sEnteredMapMarkerString =  vehicle.sEnteredMapMarkerString;
	self.currentInput = vehicle.currentInput;

	
	--print("event new")
    return self;
end;

function AutoDriveInputEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, networkGetObjectId(self.vehicle));
	
	streamWriteBool(streamId, self.bActive);
	streamWriteBool(streamId, self.bRoundTrip);
	streamWriteBool(streamId, self.bReverseTrack);
	streamWriteBool(streamId, self.bDrivingForward);
	
	streamWriteFloat32(streamId, self.nTargetX);
	streamWriteFloat32(streamId, self.nTargetZ);
	
	streamWriteBool(streamId, self.bInitialized);
	
	self.wayPointsString = "";
	for i, point in pairs(self.wayPoints) do 
		if self.wayPointsString == "" then
			self.wayPointsString = self.wayPointsString .. point.id;
		else
			self.wayPointsString = self.wayPointsString .. "," .. point.id;
		end;
	end;
	streamWriteString(streamId, self.wayPointsString);
		
	streamWriteBool(streamId, self.bcreateMode);
	streamWriteFloat32(streamId, self.nCurrentWayPoint);
	streamWriteFloat32(streamId, self.nlastLogged);
	streamWriteFloat32(streamId, self.nloggingInterval);
	streamWriteString(streamId, self.logMessage);
	streamWriteFloat32(streamId, self.nPrintTime);
	streamWriteFloat32(streamId, self.ntargetSelected);
	streamWriteBool(streamId, self.bTargetMode);
	streamWriteFloat32(streamId, self.nMapMarkerSelected);
	streamWriteFloat32(streamId, self.nSpeed);
	streamWriteBool(streamId, self.bCreateMapPoints);
	streamWriteBool(streamId, self.bShowDebugMapMarker);
	streamWriteFloat32(streamId, self.nSelectedDebugPoint);
	streamWriteBool(streamId, self.bShowSelectedDebugPoint);
	streamWriteBool(streamId, self.bChangeSelectedDebugPoint);
	
	self.debugPointsIteratedString = "";
	for i, point in pairs(self.DebugPointsIterated) do 
		if self.debugPointsIteratedString == "" then
			self.debugPointsIteratedString = debugPointsIteratedString .. point.id;
		else
			
			self.debugPointsIteratedString = debugPointsIteratedString .. "," .. point.id;
		end;
	end;
	streamWriteString(streamId, self.debugPointsIteratedString);
	
	
	streamWriteString(streamId, self.sTargetSelected);	
	streamWriteBool(streamId, self.bStopAD);
	streamWriteBool(streamId, self.bforceIsActive);
	streamWriteBool(streamId, self.bStopMotorOnLeave);

	streamWriteBool(streamId, self.bDeadLock);
	streamWriteFloat32(streamId, self.nTimeToDeadLock);
	streamWriteFloat32(streamId, self.bDeadLockRepairCounter);
	streamWriteBool(streamId, self.bCreateMapMarker);
	streamWriteBool(streamId, self.bEnteringMapMarker);
	streamWriteString(streamId, self.sEnteredMapMarkerString);
	streamWriteString(streamId, self.currentInput);
	-- print("event writeStream")
end;

function AutoDriveInputEvent:readStream(streamId, connection)
    --print("Received Event");
	
	local id = streamReadInt32(streamId);
    local vehicle = networkGetObject(id);
	
	local bActive = streamReadBool(streamId);
	local bRoundTrip = streamReadBool(streamId);
	local bReverseTrack = streamReadBool(streamId);
	local bDrivingForward = streamReadBool(streamId);
	local nTargetX = streamReadFloat32(streamId);
	local nTargetZ = streamReadFloat32(streamId);
	local bInitialized = streamReadBool(streamId);
	
	local wayPointsString = streamReadString(streamId);
	local wayPointID = Utils.splitString(",", wayPointsString);
	local wayPoints = {};
	for i,id in pairs(wayPointID) do
		wayPoints[i] = g_currentMission.AutoDrive.mapWayPoints[id];
	end;
	
	local bcreateMode = streamReadBool(streamId);
	local nCurrentWayPoint = streamReadFloat32(streamId);
	local nlastLogged = streamReadFloat32(streamId);
	local nloggingInterval = streamReadFloat32(streamId);
	local logMessage = streamReadString(streamId);
	local nPrintTime = streamReadFloat32(streamId);
	local ntargetSelected = streamReadFloat32(streamId);
	local bTargetMode = streamReadBool(streamId);
	local nMapMarkerSelected = streamReadFloat32(streamId);
	local nSpeed = streamReadFloat32(streamId);
	local bCreateMapPoints = streamReadBool(streamId);
	local bShowDebugMapMarker = streamReadBool(streamId);
	local nSelectedDebugPoint = streamReadFloat32(streamId);
	local bShowSelectedDebugPoint = streamReadBool(streamId);
	local bChangeSelectedDebugPoint = streamReadBool(streamId);
	
	local DebugPointsIteratedString = streamReadString(streamId);
	local DebugPointsID = Utils.splitString(",", DebugPointsIteratedString);
	local DebugPointsIterated = {};
	for i,id in pairs(DebugPointsID) do
		DebugPointsID[i] = g_currentMission.AutoDrive.mapWayPoints[id];
	end;
	
	local sTargetSelected = streamReadString(streamId);
	local bStopAD = streamReadBool(streamId);
	local bforceIsActive = streamReadBool(streamId);
	local bStopMotorOnLeave = streamReadBool(streamId);

	local bDeadLock = streamReadBool(streamId);
	local nTimeToDeadLock = streamReadFloat32(streamId);
	local bDeadLockRepairCounter = streamReadFloat32(streamId);
	local bCreateMapMarker = streamReadBool(streamId);
	local bEnteringMapMarker = streamReadBool(streamId);
	local sEnteredMapMarkerString = streamReadString(streamId);
	local currentInput = streamReadString(streamId);

	if g_server ~= nil then
		vehicle.currentInput = currentInput;
	else
		vehicle.bActive = bActive;
		vehicle.bRoundTrip = bRoundTrip;
		vehicle.bReverseTrack = bReverseTrack ;
		vehicle.bDrivingForward = bDrivingForward;
		vehicle.nTargetX = nTargetX ;
		vehicle.nTargetZ = nTargetZ;
		vehicle.bInitialized = bInitialized;
		vehicle.ad.wayPoints = wayPoints ;
		vehicle.bcreateMode = bcreateMode;
		vehicle.nCurrentWayPoint = nCurrentWayPoint ;
		vehicle.nlastLogged = nlastLogged;
		vehicle.nloggingInterval = nloggingInterval;
		vehicle.logMessage = logMessage;
		vehicle.nPrintTime = nPrintTime;
		vehicle.ntargetSelected = ntargetSelected;
		vehicle.bTargetMode = bTargetMode;
		vehicle.nMapMarkerSelected = nMapMarkerSelected ;
		vehicle.nSpeed = nSpeed;
		vehicle.bCreateMapPoints = bCreateMapPoints;
		vehicle.bShowDebugMapMarker = bShowDebugMapMarker;
		vehicle.nSelectedDebugPoint = nSelectedDebugPoint;
		vehicle.bShowSelectedDebugPoint = bShowSelectedDebugPoint;
		vehicle.bChangeSelectedDebugPoint = bChangeSelectedDebugPoint;
		vehicle.DebugPointsIterated = DebugPointsIterated ;
		vehicle.sTargetSelected = sTargetSelected;
		vehicle.bStopAD = bStopAD;
		vehicle.forceIsActive = bforceIsActive;
		vehicle.stopMotorOnLeave = bStopMotorOnLeave;

		vehicle.bDeadLock = bDeadLock;
		vehicle.nTimeToDeadLock = nTimeToDeadLock;
		vehicle.bDeadLockRepairCounter = bDeadLockRepairCounter;
		vehicle.bCreateMapMarker = bCreateMapMarker;
		vehicle.bEnteringMapMarker = bEnteringMapMarker;
		vehicle.sEnteredMapMarkerString = sEnteredMapMarkerString


	end;



		
	if g_server ~= nil then	
		g_server:broadcastEvent(AutoDriveInputEvent:new(vehicle), nil, nil, vehicle);
		-- print("broadcasting")
	end;
end;

function AutoDriveInputEvent:sendEvent(vehicle)
	if g_server ~= nil then	
		g_server:broadcastEvent(AutoDriveInputEvent:new(vehicle), nil, nil, vehicle);
		-- print("broadcasting")
	else
		g_client:getServerConnection():sendEvent(AutoDriveInputEvent:new(vehicle));
		-- print("sending event to server...")
	end;
end;


--MapEvent%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--MapEvent%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--MapEvent%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


AutoDriveMapEvent = {};
AutoDriveMapEvent_mt = Class(AutoDriveMapEvent, Event);

InitEventClass(AutoDriveMapEvent, "AutoDriveMapEvent");

function AutoDriveMapEvent:emptyNew()
	local self = Event:new(AutoDriveMapEvent_mt);
	self.className="AutoDriveMapEvent";
	return self;
end;

function AutoDriveMapEvent:new(vehicle)
	local self = AutoDriveMapEvent:emptyNew()
	self.vehicle = vehicle;
	--print("event new")
	return self;
end;

function AutoDriveMapEvent:writeStream(streamId, connection)

	if g_server ~= nil then
		print("Broadcasting waypoints");

		local idFullTable = {};
		local idString = "";
		local idCounter = 0;

		local xTable = {};
		local xString = "";

		local yTable = {};
		local yString = "";

		local zTable = {};
		local zString = "";

		local outTable = {};
		local outString = "";

		local incomingTable = {};
		local incomingString = "";

		local out_costTable = {};
		local out_costString = "";

		local markerNamesTable = {};
		local markerNames = "";

		local markerIDsTable = {};
		local markerIDs = "";

		for i,p in pairs(g_currentMission.AutoDrive.mapWayPoints) do

			--idString = idString .. p.id .. ",";
			idFullTable[i] = p.id;
			idCounter = idCounter + 1;
			--xString = xString .. p.x .. ",";
			xTable[i] = p.x;
			--yString = yString .. p.y .. ",";
			yTable[i] = p.y;
			--zString = zString .. p.z .. ",";
			zTable[i] = p.z;

			--outString = outString .. table.concat(p.out, ",") .. ";";
			outTable[i] = table.concat(p.out, ",");

			local innerIncomingTable = {};
			local innerIncomingCounter = 1;
			for i2, p2 in pairs(g_currentMission.AutoDrive.mapWayPoints) do
				for i3, out2 in pairs(p2.out) do
					if out2 == p.id then
						innerIncomingTable[innerIncomingCounter] = p2.id;
						innerIncomingCounter = innerIncomingCounter + 1;
						--incomingString = incomingString .. p2.id .. ",";
					end;
				end;
			end;
			incomingTable[i] = table.concat(innerIncomingTable, ",");
			--incomingString = incomingString .. ";";

			out_costTable[i] = table.concat(p.out_cost, ",");
			--out_costString = out_costString .. table.concat(p.out_cost, ",") .. ";";

			local markerCounter = 1;
			local innerMarkerNamesTable = {};
			local innerMarkerIDsTable = {};
			for i2,marker in pairs(p.marker) do
				innerMarkerIDsTable[markerCounter] = marker;
				--markerIDs = markerIDs .. marker .. ",";
				innerMarkerNamesTable[markerCounter] = i2;
				--markerNames = markerNames .. i2 .. ",";
				markerCounter = markerCounter + 1;
			end;

			markerNamesTable[i] = table.concat(innerMarkerNamesTable, ",");
			markerIDsTable[i] = table.concat(innerMarkerIDsTable, ",");

			--markerIDs = markerIDs .. ";";
			--markerNames = markerNames .. ";";
		end;

		if idFullTable[1] ~= nil then
			streamWriteFloat32(streamId, idCounter);
			local i = 1;
			while i <= idCounter do
				streamWriteFloat32(streamId,idFullTable[i]);
				streamWriteFloat32(streamId,xTable[i]);
				streamWriteFloat32(streamId,yTable[i]);
				streamWriteFloat32(streamId,zTable[i]);
				streamWriteString(streamId,outTable[i]);
				streamWriteString(streamId,incomingTable[i]);
				streamWriteString(streamId,out_costTable[i]);
				if markerIDsTable[1] ~= nil then
					streamWriteString(streamId, markerIDsTable[i]);
					streamWriteString(streamId, markerNamesTable[i]);
				else
					streamWriteString(streamId, "");
					streamWriteString(streamId, "");
				end;
				i = i + 1;

			end;
		end;

		local markerIDs = "";
		local markerNames = "";
		local markerCounter = 0;
		for i in pairs(g_currentMission.AutoDrive.mapMarker) do
			markerCounter = markerCounter + 1;
		end;
		streamWriteFloat32(streamId, markerCounter);
		local i = 1;
		while i <= markerCounter do
			streamWriteFloat32(streamId, g_currentMission.AutoDrive.mapMarker[i].id);
			streamWriteString(streamId, g_currentMission.AutoDrive.mapMarker[i].name);
			i = i + 1;
		end;




	else
		print("Requesting waypoints");
		streamWriteInt32(streamId, networkGetObjectId(self.vehicle));
	end;

	--print("event writeStream")
end;

function AutoDriveMapEvent:readStream(streamId, connection)
	print("Received Event");

	if g_server ~= nil then
		print("Receiving request for broadcasting waypoints");
		local id = streamReadInt32(streamId);
		local vehicle = networkGetObject(id);

		AutoDriveMapEvent:sendEvent(vehicle)
	else
		print("Receiving waypoints");
		if g_currentMission.AutoDrive.receivedWaypoints ~= true then

			local pointCounter = streamReadFloat32(streamId);
			if pointCounter > 0 then
				g_currentMission.AutoDrive.mapWayPoints = {};
			end;

			local wp_counter = 0;
			while wp_counter < pointCounter do


					wp_counter = wp_counter +1;
					local wp = {};
					wp["id"] =  streamReadFloat32(streamId);
					wp.x = streamReadFloat32(streamId);
					wp.y =	streamReadFloat32(streamId);
					wp.z = streamReadFloat32(streamId);

					local outString = streamReadString(streamId);
					local outTable = Utils.splitString("," , outString);
					wp["out"] = {};
					for i2,outString in pairs(outTable) do
						wp["out"][i2] = tonumber(outString);
					end;

					local incomingString = streamReadString(streamId);
					local incomingTable = Utils.splitString("," , incomingString);
					wp["incoming"] = {};
					local incoming_counter = 1;
					for i2, incomingID in pairs(incomingTable) do
						if incomingID ~= "" then
							wp["incoming"][incoming_counter] = tonumber(incomingID);
						end;
						incoming_counter = incoming_counter +1;
					end;

					local out_costString = streamReadString(streamId);
					local out_costTable = Utils.splitString("," , out_costString);
					wp["out_cost"] = {};
					for i2,out_costString in pairs(out_costTable) do
						wp["out_cost"][i2] = tonumber(out_costString);
					end;



					local markerIDsString = streamReadString(streamId);
					local markerIDsTable = Utils.splitString("," , markerIDsString);
					local markerNamesString = streamReadString(streamId);
					local markerNamesTable = Utils.splitString("," , markerNamesString);
					wp["marker"] = {};
					for i2, markerName in pairs(markerNamesTable) do
						if markerName ~= "" then
							wp.marker[markerName] = tonumber(markerIDsTable[i2]);
						end;
					end;

					g_currentMission.AutoDrive.mapWayPoints[wp_counter] = wp;
			end;

			if g_currentMission.AutoDrive.mapWayPoints[wp_counter] ~= nil then
				print("AD: Loaded Waypoints: " .. wp_counter);
				g_currentMission.AutoDrive.mapWayPointsCounter = wp_counter;
			else
				g_currentMission.AutoDrive.mapWayPointsCounter = 0;
			end;

			local mapMarkerCounter = streamReadFloat32(streamId);
			local mapMarkerCount = 1;

			if mapMarkerCounter ~= 0 then
				g_currentMission.AutoDrive.mapMarker = {}
				print("AD: Loaded Destinations: " .. mapMarkerCounter);
			end;

			while mapMarkerCount <= mapMarkerCounter do
				local markerId = streamReadFloat32(streamId);
				local markerName = streamReadString(streamId);
				local marker = {};
				marker.id = markerId;
				marker.name = markerName;

				g_currentMission.AutoDrive.mapMarker[mapMarkerCount] = marker;
				mapMarkerCount = mapMarkerCount + 1;
			end;
			g_currentMission.AutoDrive.mapMarkerCounter = mapMarkerCounter;

			g_currentMission.AutoDrive.receivedWaypoints = true;
		end;

	end;


end;

function AutoDriveMapEvent:sendEvent(vehicle)
	if g_server ~= nil then
		g_server:broadcastEvent(AutoDriveMapEvent:new(vehicle), nil, nil, nil);
		--print("broadcasting")
	else
		g_client:getServerConnection():sendEvent(AutoDriveMapEvent:new(vehicle));
		--print("sending event to server...")
	end;
end;

--StoreBackup%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--StoreBackup%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--StoreBackup%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function AutoDrive.backupADFiles(self)
	if g_server == nil and g_dedicatedServerInfo == nil then return end;

	if not fileExists(g_currentMission.AutoDrive.xmlSaveFile) then
		-- ERROR: CP FILE DOESN'T EXIST
		return;
	end;

	local savegameIndex = g_currentMission.missionInfo.savegameIndex;
	AutoDrive.adTempSaveFolderPath = getUserProfileAppPath() .. 'autoDriveBackupSavegame' .. savegameIndex;
	createFolder(AutoDrive.adTempSaveFolderPath);

	AutoDrive.adFileBackupPath = AutoDrive.adTempSaveFolderPath .. '/AutoDrive_config.xml';
	copyFile(g_currentMission.AutoDrive.xmlSaveFile, AutoDrive.adFileBackupPath, true);

end;
g_careerScreen.saveSavegame = Utils.prependedFunction(g_careerScreen.saveSavegame, AutoDrive.backupADFiles);

function AutoDrive.restoreBackup(self)
	if g_server == nil and g_dedicatedServerInfo == nil then return end;

	if not AutoDrive.adFileBackupPath then return end;

	local savegameIndex = g_currentMission.missionInfo.savegameIndex;
	local savegameFolderPath = getUserProfileAppPath() .. "savegame" .. g_currentMission.missionInfo.savegameIndex;


	if fileExists(savegameFolderPath .. '/careerSavegame.xml') then -- savegame isn't corrupted and has been saved correctly

		-- copy backed up files back to our savegame directory
		copyFile(AutoDrive.adFileBackupPath, g_currentMission.AutoDrive.xmlSaveFile, true);
		AutoDrive.adFileBackupPath = nil;

	end;
end;
g_careerScreen.saveSavegame = Utils.appendedFunction(g_careerScreen.saveSavegame, AutoDrive.restoreBackup);