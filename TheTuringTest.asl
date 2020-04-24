state("theturingtest")
{
	byte 	chapter		:0x2DB9060,0x110;
	short 	sector		:0x2DB9060,0x114;
	bool 	loading		:0x2DB9070,0x19;
	bool 	stream		:0x2D5ADB0,0x70,0x268,0x238,0x4E0,0x558;
	bool 	inProgress	:0x2F18AF8,0x40,0x20,0x69F;
	float 	xSpeed		:0x2D89400,0x0,0x3E8,0xDC;
	float 	ySpeed		:0x2D89400,0x0,0x3E8,0xE0;
	float 	zSpeed		:0x2D89400,0x0,0x3E8,0xE4;
}
startup
{
	vars.splitsEnabled=true;
	vars.splitOnSector=0;
	vars.startOffset="-00:00:51.3200000";
	vars.printFormat="[TheTuringTestASL] {0} change: {1} -> {2}";
	settings.Add("Offset",true,"Set Start Offset to -00:51.32");
	settings.Add("Debug",false);
	vars.speedAbs=0f;
}
init
{
	version="1.3 DX11";
	var splits=timer.Run.Count;
	var message="";
	if(splits<9||splits>78||!settings.SplitEnabled){
		vars.splitsEnabled=false;
		message="Autosplitting is disabled.";
		MessageBox.Show(splits+" splits found.\n"+
			message,"TheTuringTestASL | LiveSplit",
			MessageBoxButtons.OK,MessageBoxIcon.Information);
	}
	else if(splits==72){
		vars.splitOnSector=1;
		message="Will split on MAIN Sector changes.";
	}
	else if(splits==78){
		vars.splitOnSector=2;
		message="Will split on ALL Sector changes.";
	}
	else{message="Will split on Chapter changes.";}
	
	if(settings["Debug"])
		print("[TheTuringTestASL] "+splits+" splits found. "+message);
	
	if(settings["Offset"] && timer.Run.Offset.ToString()!=vars.startOffset){
		MessageBox.Show("Timer start offset is currently set to: "+
			timer.Run.Offset.ToString()+".\nThis will be changed to "+
			vars.startOffset+".\nThis can be disabled in the autosplitter settings window.",
			"TheTuringTestASL | LiveSplit",
			MessageBoxButtons.OK, MessageBoxIcon.Warning);
	}
	timer.IsGameTimePaused=false;
}
start
{
	if(settings["Offset"]&&timer.Run.Offset.ToString()!=vars.startOffset){
		print("[TheTuringTestASL] Run start offset was "+
			timer.Run.Offset.ToString()+", setting to "+vars.startOffset);
			timer.Run.Offset=TimeSpan.Parse(vars.startOffset);
	}
	return current.chapter==0&&current.sector==-1&&!current.loading&&old.loading;
}
update
{
	if (settings["Debug"]&&current.chapter!=old.chapter)
		print(String.Format(vars.printFormat,"Chapter",
			old.chapter,current.chapter));
	
	if(settings["Debug"]&&current.sector!=old.sector)
		print(String.Format(vars.printFormat,"Sector",
			old.sector,current.sector));
	//Speed absolute value
	if(current.stream)
		vars.speedAbs=Math.Sqrt(
			Math.Pow(current.xSpeed,2)+
			Math.Pow(current.ySpeed,2)+
			Math.Pow(current.zSpeed,2));
}
isLoading{
	//Don't pause game time while moving during streaming load
	if(current.stream&&current.loading&&vars.speedAbs!=0)
		return false;
	
	return current.loading;
}
reset{return current.chapter==0&&current.sector==-1&&current.loading;}
split
{
	if(!vars.splitsEnabled) return;
	if(vars.splitOnSector>0&&current.sector>old.sector){
		//OoB Sector Changes
		if( (old.sector==26&&current.sector>27&&current.sector<30)|| //C26
			(old.sector==36&&current.sector>37&&current.sector<40)|| //D36
			(old.sector==66&&current.sector>37&&current.sector<40) ) //G66
			timer.CurrentSplitIndex=timer.CurrentSplitIndex+
				(current.sector-old.sector);
		//Story Sectors
		else if(vars.splitOnSector==2 && current.sector>1000)
			return current.sector>old.sector;
		//Normal Sectors
		else return current.sector>old.sector&&current.sector<1000;
	}
	//Final Split
	else if(current.chapter==8&&!current.inProgress&&old.inProgress)
		return current.inProgress != old.inProgress;
	
	else return current.chapter>old.chapter;
}
exit{timer.IsGameTimePaused=true;}
