" increase font size and outline size
argadd *.ass
argdo %s/\VStyle: Default,MS UI Gothic,60,&H00FFFFFF,&H000000FF,&H00000000,&H00000000,0,0,0,0,100,100,5,0,1,1,2,1,10,10,10,0/Style: Default,MS UI Gothic,100,\&H00FFFFFF,\&H000000FF,\&H00000000,\&H00000000,0,0,0,0,100,100,5,0,1,6,2,1,10,10,10,0/ge | update
argdo %s/\VStyle: Rubi,MS UI Gothic,50,&H00FFFFFF,&H000000FF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,2,2,1,10,10,10,0/Style: Rubi,MS UI Gothic,100,\&H00FFFFFF,\&H000000FF,\&H00000000,\&H00000000,0,0,0,0,100,100,0,0,1,2,6,1,10,10,10,0/ge | update
