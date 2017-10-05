function ticker_common()
	local list=split("bait only works on adult aliens;"..current_level.eggs.." eggs remaining;use \142 to scan area;camo aliens cannot be killed;camo alien attack paralyzes;scanner will recharge over time;scanning uses battery power;bait only lasts a few moments;baby aliens search for bodies;use your items wisely;aliens will attack if you get too close")
	add_ticker_text(rnd_table(list)..";")
	printh("generic text")
end

if gt>=1200 then -- toss in generic messages every 8 seconds 
		if current_level.eggs<=0 then
			add_ticker_text("no more eggs detected;return to transport beacon immediately")
		else
			ticker_common()
		end
		
		gt=0
	end


firstplay=true
if firstplay then story_init(true) else start_init() end


-- #story
function story_init(go)
	local sx=1
	local lspr=14
    
    fd_init()

	function story_update()
		if btnxp or btnzp or gt>sec(12) then 
			if go then 
				start_init()
				firstplay=false
			else title_init() end 
		end
		
		if gt>sec(5) then
			lspr=160
			if sx>=80 then lspr=128 end
			
			sx=min(sx+.5,130)
		end
        
        fd_update()
	end 

	function story_draw()
		center_text("dylan burke is finishing the;job his father failed to;complete on lv-426.;;you know what that means and he;must be stopped.;;explore planets and collect;alien eggs before burke can;get to them.",8, fd_c)
		palt(2,true)
		spr(lspr,sx,105,2,2)
		if sx<80 then spr(9, 80,111,2,1) end
		pal()
	end


	cart(story_update,story_draw)
end



-- boot loop with rainbow fade out
-- #loop

function _init()
    
	rb_i=0
	--title_init()
end


function _update60()
	if rb_i==98 then title_init() rb_i=99 end
	
	btnl=btn(0)
	btnr=btn(1)
	btnu=btn(2)
	btnd=btn(3)
	btnzp=btnp(4)
	btnxp=btnp(5)
	
	cart_update()

	gt=min(25000,gt+1)
end


function _draw()
	if rb_i<16 then
		for x=0,127 do
			for y=0,127 do
				if pget(x,y)!=0 then 
					pset(x,y,pget(x,y)-1) 
				end
			end
		end
		rb_i+=1
	else
		if rb_i<99 then rb_i=98 end
		cls()
		cart_draw()
	end
	
	
	-- debug memory
	--camera(0,0)
	--print(flr((stat(0)/1024)*100).."%m\n"..stat(1).."\n"..debug,100,0,8)
end