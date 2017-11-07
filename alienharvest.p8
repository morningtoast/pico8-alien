pico-8 cartridge // http://www.pico-8.com
version 11
__lua__
--alien harvest
--brian vaughn, 2017


tm,tmo,gt=0,false,0
txt_rtt="return to transport beacon"

-- #player
function p_upd()
	if gameover<1 then
		if not mini_mode and p_freeze==0 then
			mini_batt=max(mini_batt-1,0)

			p_cx=p_x+8
			p_cy=p_y+8

			p_tx,p_ty=px_to_tile(p_cx,p_cy)
			p_dx,p_dy,p_xdir,p_ydir=0,0,0,0

			local tile=get_tile(p_tx,p_ty)

			if btnl	then p_dx=-1 p_flip=true end
			if btnr	then p_dx=1 p_flip=false end
			if btnu	then p_dy=-1 end
			if btnd	then p_dy=1 end



			if p_dx!=0 or p_dy!=0 then 
				p_spr=anim(p_anim)
			else
				p_spr=anim(p_anim,true)
			end

			if not blocked(p_x,p_y, p_dx,p_dy, {y=6,x=6,w=4,h=4}) then
				p_x+=p_dx
				p_y+=p_dy
			end



			p_tiles(tile)

			if btnxp then
				if p_st==2 then
					sfx(13)
					p_bullet()
				end

				if p_st==3 then
					sfx(14)
					add_bait(p_cx,p_cy)
				end

				p_st=1
				p_anim={l={32,34,36,34},f=1,r=8}
				p_spr=anim(p_anim,true)
			end

			if btnzp then
				if not tmo then
					if mini_batt<=0 then
						sfx(17)
						mini_mode=true
						gen_mini()
					else
						sfx(12)
						tkr("scanner battery recharging",true)
					end
				else
					sfx(12)
					tkr("scanner broken",true)
				end
			end
		else
			if btnzp and p_freeze==0 then
				mini_mode=false
				mini_batt=sec(7)
			end
		end
		
	end
	
	
	if p_freeze>0 then p_freeze-=1 end
end

function p_drw()
	if p_freeze>0 then pal(10,13) end
	spr(p_spr, p_x,p_y, 2,2, p_flip)
end


function p_tiles(tile)
	if tile.o==4 then
		sfx(16)
		if yesno() or (level_id==3 and dget(3)<1) then
			p_st,p_spr=2,64
			p_anim={l={64,66,68,66},f=1,r=8}
			tkr("pulse rifle equipped",true)
		else
			p_st,p_spr=3,96
			p_anim={l={96,98,100,98},f=1,r=8}
			tkr("bait equipped",true)
		end
		
		p_spr=anim(p_anim,true)
		p_bodies+=1
		bishop=false
		
		if tmo then 
			if lvl.bodies==p_bodies then
				achv_c+=1
				unlock(2)
			end
		end

		tile_attr(p_tx,p_ty)
	end
	
	if tile.o==3 then
		local cargo="cargo bay is full;"..txt_rtt
		if p_eggs<quota then
			p_eggs=min(p_eggs+1,quota)
			lvl.eggs=max(lvl.eggs-1,0)
			
            sfx(16)
			tile_attr(p_tx,p_ty)
			tkr("alien egg collected",true)
			
			if p_eggs<quota then 
				if lvl.eggs<=0 then
					tkr(txt_rtt)
				else
					tkr(lvl.eggs.." eggs remaining") 
				end
			else
				tkr(cargo)
				sfx(11)
			end
			
			
		else
			if tile_t==0 then
                sfx(12)
				tkr(cargo,true)
			end
		end
		tile_t+=1
	else
		tile_t=0
	end
	
	
	-- #transport
	if tile.o==6 then
		local lt="wait at beacon. dropship landing;leaving "..lvl.name
		local ds="dropship unavailable"
		if tran_st==0 then tran_st=1 end
		
		if not finale then
			if (lvl.eggs<=0 or p_eggs==quota) and tran_t==0 then
				sfx(15)
				tkr(lt,true)
				tran_st=2
			else
				if tran_t==0 then 
					sfx(12)
					tkr(ds..";find remaining eggs",true) 
				end
			end
			
			if tran_t==sec(tran_w) and tran_st==2 then
				if p_eggs==quota then
					finale_init()
				else
					start_init()	
				end
			end
			
		else
			if det_st==2 then
				if tran_t==0 then
					sfx(15)
					tkr(lt,true)
					tran_st=2
				end
				
				if tran_t==sec(tran_w) and tran_st==2 then
					vic_init()
				end
			else
				
				if tran_t==0 then 
					sfx(12)
					tkr(ds..";find detonator",true) 
				end
			end
		end
		
		tran_t+=1
	else
		if tran_st==2 then
			sfx(12)
			tkr("dropship canceled. "..txt_rtt,true)
		end
        tran_t,tran_st=0,0
	end
	
	
	
	-- #bombarm
	if tile.o==7 then
		if bomb_t==0 then 
			sfx(18)
			tkr("arming bomb",true) 
		end

		tile.bomb_st=1

		if bomb_t==sec(2) then 
			lvl.bombs=max(0,lvl.bombs-1)


			sfx(11)
			tkr("bomb armed and ready",true) 

			if lvl.bombs>0 then
				tkr(lvl.bombs.." bombs remaining") 
			else
				tkr("all bombs armed;find detonator") 
			end

			tile_attr(p_tx,p_ty)
		end
		
		bomb_t+=1
	else
		bomb_t,tile.bomb_st=0,0
	end
	
	
	-- #detonator
	if tile.o==8 then
		if lvl.bombs==0 then
			if det_st<2 then
				if det_t==0 then
                    sfx(18)
					tkr("stand by, intializing...",true) 
				end

				det_st=1

				if det_t==sec(4) then
					det_st=2
					tkr("countdown started;"..txt_rtt,true)
                    sfx(19)
					music(3,6000)
					tile_attr(p_tx,p_ty)
					lvl.hatch-=7
				end
			end
		else 
			if det_t==0 then sfx(12) tkr("find all bombs first",true) end
		end
		
		det_t+=1
	else
		if det_st==1 then
			sfx(12)
			tkr("countdown aborted",true)
			det_st=0
		end
		det_t=0
	end	
	
	
	if tile.o==98 and det_st==2 then
		sfx(16)
		tile_attr(p_tx,p_ty)
		jones=true
	end
end

function p_bullet()
	local tgt={}
	local heading=0
	
	local obj={
		x=p_cx,y=p_y+5,c=10,
		update=function(b)
			for k,a in pairs(actors) do
				if a.id<3 and in_range(b.x,b.y, a.cx,a.cy, 12) then
					chg_st(a,99)
					b:rm()
				end
			end
		end,
		rm=function(b) del(bullets,b) end
	}
	
	
	if p_flip then heading=.5 end

	for k,a in pairs(actors) do
		if a.id<3 then
			if in_range(a.cx,a.cy, p_cx,p_cy, 60) then add(tgt,a) end
		end
	end

	if #tgt>0 then
		local tgt = find_nearest(p_cx,p_cy, tgt)
		heading   = atan2(tgt.cx-p_cx, tgt.cy-p_cy) 
	end

	obj.dx,obj.dy = dir_calc(heading, 3)


	add(bullets,obj)	
end

-- #levels
function start_init()
	music(-1)

	local rc=rnd_table({{3,4},{11,9},{11,4},{15,14},{9,4},{11,3},{2,1}})
	
    if not finale then
        level_id+=1

        local levels={
            {name="jl-78",w=3,h=3,bombs=0,bodies=2,eggs=2,hatch=45,aliens=0,snipers=0,colors={11,3}},
            {name="col-b",w=4,h=4,bombs=0,bodies=4,eggs=3,hatch=35,aliens=1,snipers=1,colors={11,4}},
            {name="pv-418",w=5,h=3,bombs=0,bodies=7,eggs=4,hatch=25,aliens=2,snipers=2,colors={14,2}},
            {name="gva-1106",w=3,h=6,bombs=0,bodies=7,eggs=5,hatch=20,aliens=3,snipers=3,colors={9,4}},
            {name="bv-1031",w=5,h=5,bombs=0,bodies=9,eggs=6,hatch=20,aliens=3,snipers=3,colors={4,3}},
            {name="al-18",w=3,h=7,bombs=0,bodies=10,eggs=6,hatch=20,aliens=2,snipers=4,colors={2,1}}
        }


        if level_id>5 or tmo then
            local abc=split("a;b;c;d;e;f;g;h;i;j;k;l;m;n;o;p;q;r;s;t;u;w;v;y;z")
            local name=rnd_table(abc)..rnd_table(abc).."-"..random(75,850)
            local mw=random(4,6)
            local mh=random(4,6)
            local me=min(mw,mh)
            local mb=me+random(2,4)
            local ma=random(1,3)
            local ms=random(2,5)

            if level_id>7 then
                if mw<5 then mh=7 end
                if mh<5 then mw=7 end
            end

            lvl={name=name,w=mw,h=mh,bodies=mb,eggs=me,hatch=20,aliens=ma,snipers=ms,bombs=0,colors=rc}	
        else
            lvl=levels[level_id]
        end
    else 
    	local mw,mh=8,4
    	if yesno() then mw,mh=4,8 end 
        lvl={name="pco-8",w=mw,h=mh,bodies=15,eggs=3,hatch=20,aliens=3,snipers=5,bombs=3,colors=rc}	
		
		if tmo then 
			lvl.hatch=15 
			lvl.eggs=5
		end
	end

	
	function start_upd()
		if btnzp then play_init() end
	end
	
	
	function start_drw()
		draw_console()
		
		cprint("mission: "..lvl.name, 8, 10)
		
		local ax=32
		if finale then
			spr(110, 8,17, 2,2)
			print("find and arm\n3 remote bombs", ax,21, 7)
				
			spr(108, 8,38, 2,2)
			print("then find detonator\nto start countdown",ax,41, 7)
				
			spr(12, 8,60, 2,2)
			print("wait at transport\nbeacon to escape",ax,61, 7)
		else
			spr(14, 8,18, 2,2)
			print(lvl.eggs.." eggs detected.\ncollect as many as you\ncan before they hatch.", ax,22, 7)

			spr(12, 8,53, 2,2)
			print("wait at beacon when\neggs are gone\n",ax,55, 7)
		end
		
		print("press z to start",ax,83, 11)
	end
	
	cart(start_upd,start_drw)
	
end


function draw_console(nl)
	rect(0,0, 127,127, 12)
	rect(2,2, 125,93, 12)

	rect(89,95, 125,125, 12)
	rect(2,95, 87,125, 12)

	if not nl then zspr(74,2,1,90,103, 2, 1) end
	
	print("cargo bay: "..p_eggs.."/"..quota,7,100,7)
		
	local ix=5
	local iy=107

	for n=1,quota do
		if n<=p_eggs then pal(13,10) end
		spr(26,ix,iy,1,1) pal()
		ix+=8

		if n==10 then ix=5 iy+=8 end
	end	
	
end




-- #game play 
function play_init()
	p_x,p_y,p_spr=0,0,32
	p_anim={l={32,34,36,34},f=1,r=8}
	p_st,p_flip,p_freeze=0,false,0
	egg_t=sec(lvl.hatch)
	tran_st=0
	
	tkr_x,tkr_end,tkr_t=105,105,0
	tkr_log={}

	sfx_n,sfx_l=3,3
	sfx_t=sec(sfx_n)
	
	mini_mode=false
	mini_batt=0

	h_kills=0
	p_bodies=0
	h_eggs=lvl.eggs
	
	actors={}
	bullets={}

	gen_map(lvl.w,lvl.h)
	
	local txt="arrival on "..lvl.name
	tkr(txt,true)
	
	if level_id==1 then
		tkr("press z for map scan;press x to use weapon")	
	end
	
	if finale then
		tkr("find and arm 3 bombs")
	else
		tkr("scan shows "..lvl.eggs.." eggs in range")	
	end


	cart(play_upd,play_drw)
end

function play_upd()
	p_upd()
	
	function _t()
		if lvl.eggs<=0 then
			sfx(11)
			return "no more eggs detected;"..txt_rtt
		else
			return lvl.eggs.." eggs remaining"
		end	
	end
	
	if gameover<1 then
		if lvl.eggs>0 then
			egg_t=max(0,egg_t-1)
			
			if egg_t==sec(1.25) then
				l_egg=get_rndtile(3)
				tile_attr(l_egg.tx,l_egg.ty,"s",70)
			end

			if egg_t<=0 then
				tile_attr(l_egg.tx,l_egg.ty,"s",14)
			 	if few() then
					lvl.eggs-=1
					add_hugger(l_egg.tx,l_egg.ty) 
					tile_attr(l_egg.tx,l_egg.ty)

					tkr("egg hatch detected",true)
					sfx(11)

					if not finale then tkr(_t()) end
				end
				
				egg_t=sec(lvl.hatch)
			end
		end
	
		sfx_n=3
		
        for k,a in pairs(actors) do
			a:update()
			a.t+=1
			
			if a.id<3 and a.st<99 then
				if in_range(p_cx,p_cy, a.x,a.y,140) then
					if in_range(p_cx,p_cy, a.x,a.y,75) then
						sfx_n=min(.3,sfx_n)
					else
						sfx_n=min(.9,sfx_n)
					end
				end
			end
		end
		
		if sfx_n!=sfx_l then sfx_t=0 sfx_l=sfx_n end
		
		sfx_t=max(sfx_t-1,0)
		if sfx_t==0 then 
			sfx(10)
			sfx_t=sec(sfx_n)
		end

		
		
		if finale then
			if det_st==2 then
				countdown=max(-1,countdown-1) 
				if countdown==0 then
					sfx(20)
					music(-1)
					gameover=2
					nuke=0
					gt=0
				end
			else
				if tkr_t==sec(8) and det_st<1 then
					if lvl.bombs>0 then
						tkr(lvl.bombs.." bombs remaining",true)
					else
						tkr("find detonator to start countdown",true)
					end
				end
			end
		else
			
			if tkr_t==sec(8) then 
				tkr(_t(),true) 
			end
		end
	else
		if btnzp and gt>=sec(1) then
            music(0,3000)
			title_init()	
		end
		
		if gameover==1 then
			if blood_t>sec(4) then
				blood_t=make_blood()
			end
			
			if gt==sec(10) then
				tkr("game over;press z to restart",true)
				gt=sec(2)
			end
			
			blood_t+=1
		end
        
        if gameover==2 then
            nuke=min(150,nuke+.5)
        end
	end

	bullet_upd()
	tkr_upd()
end

function play_drw()
	camera(p_cx-64, p_cy-62)
	
	draw_map()
	bullet_drw()
	
	palt(2,true)
	palt(0,false) 
	for k,a in pairs(actors) do
		a:draw() 
	end

	p_drw()
	pal()
	
	
	
	
	camera(0,0)
	tkr_drw()
	
	

	if mini_mode then draw_mini() end
	
	
	if gameover==1 then
		for k,b in pairs(blood) do circfill(b[1],b[2],b[3], 8) end
	end
	
	if gameover==2 then
		circfill(64,64,nuke,7)	
		if nuke==150 then
			cprint("game over;;press z to restart",50,2)	
		end
	end
	
	
end

function make_blood()
	if #blood<100 then
		for n=0,15 do 
			add(blood,{random(34,94),random(34,94),random(5,9)}) 
			add(blood,{random(14,114),random(14,115),random(1,3)})
		end
	end	
	
	return 0
end




-- #ticker
function tkr(t,c)
	local l=split(t)
	if c then tkr_log={} end
	for k,t in pairs(l) do add(tkr_log,{t,(#t*4)}) end
	if c then tkr_next() end
end

function tkr_next()
	if #tkr_log>0 then
		tkr_txt=tkr_log[1][1]
		tkr_end=0-tkr_log[1][2]
		del(tkr_log, tkr_log[1])
		tkr_x,tkr_t=105,0
	end
end

function tkr_upd()
	if tkr_x>tkr_end then
		tkr_x=max(tkr_end-1,tkr_x-.8)
			
		if tkr_x<=tkr_end then tkr_next() end
	end
	tkr_t+=1
end

function tkr_drw()
	rectfill(0,117, 127,127, 1)
	
	if tkr_x>tkr_end then print(tkr_txt, tkr_x,120, 12) end

	rectfill(90,117, 127,127, 5)
	rect(0,117, 90,127,5) 


	if mini_batt>0 then pal(11,8) end
	spr(25, 94,120)
	pal()


	if finale then
		print(clock(countdown), 106,120, 6)
	else
		spr(26, 118,119)
		print(lvl.eggs, 113,120, 6)
	end
end




-- #minimap
function gen_mini() 
	minimap={}

	mini_x,mini_y=0,0

	for x=1,map_tilew do
		for y=1,map_tileh do
			local plot=grid[x][y]

			if plot.o==4 or plot.o==3 then add(minimap, {x=x,y=y,c=11}) end
			if plot.o==6 then add(minimap, {x=x,y=y,c=12}) end
		end
	end
	
	for k,a in pairs(actors) do
		if a.id<3 then add(minimap, {x=a.tx,y=a.ty,c=11}) end
	end
	
	add(minimap, {x=p_tx,y=p_ty,c=8})
end


function draw_mini()
	if map_w>5 or map_h>5 then
		if btnl then mini_x+=2 end
		if btnr then mini_x-=2 end
		if btnu then mini_y+=2 end
		if btnd then mini_y-=2 end
	end
	
	rectfill(0,0,127,93,0)
	
	rectfill(mini_x+6,mini_y+6, (map_tilew*2)+mini_x+8,(map_tileh*2)+mini_y+8, 3)
	rect(mini_x+6,mini_y+6, (map_tilew*2)+mini_x+8,(map_tileh*2)+mini_y+8, 11)

	for k,dot in pairs(minimap) do
		x1=(dot.x-1)*2+mini_x+7
		y1=(dot.y-1)*2+mini_y+7
		print("+",x1,y1-1,dot.c)
	end
	rectfill(0,93,127,127,0)
	rect(1,1,126,94,0)
	
	
	draw_console(1)
	
	print("+you",92,100,8)
	print("+beacon",92,108,12)
	print("+bio",92,116,11)
end







-- #bullets
function bullet_upd()
	for k,b in pairs(bullets) do
		b.x+=b.dx
		b.y+=b.dy

		if b.x<map_wpx and b.x>1 and b.y<map_hpx and b.y>1 then
			local tx,ty=px_to_tile(b.x,b.y)
			local t=get_tile(tx,ty)

			if t.o==1 then b:rm() end
			
			b:update()
		else
			b:rm() 
		end
	end
end


function bullet_drw()
	for k,b in pairs(bullets) do circfill(b.x,b.y, 2, b.c) end
end



-- #bait
function add_bait(x,y)
	local obj={
		id=3,
		x=x,y=y,
		cx=x+8,cy=y+8,
		t=0,
		update=function(self)
			for k,a in pairs(actors) do
				if a.id==2 and a.st<99 then
					if a.st<10 and in_range(a.cx,a.cy, self.cx,self.cy, 60) then
						local release=sec(5)-self.t
						
						chg_st(a,10)
						a.bait={x=self.cx,y=self.cy,release=release}
					end
				end
			end
		
			
			if self.t>sec(6) then del(actors,self) end
		end,
		draw=function(self)
			spr(11, self.x,self.y, 1,2)
		end
	}	

	
	add(actors,obj)
end

-- #sniper
function add_sniper(tx,ty)
	local obj={
		id=4,
		tx=tx,ty=ty,
		f=false,
		st=1,t=1,
		update=function(self)
			local ox=self.x+16
			local oy=self.y+4
			
			if self.f then ox=self.x-32 end
			
			if self.st==1 then
				if in_rec(p_cx,p_cy, ox,oy, 32,8) then
					sfx(13)
					local obj={
						dx=4,x=self.x+16,y=self.y+8,
						c=13,dy=0,
						update=function(b)
							if in_range(b.x,b.y, p_cx,p_cy, 10) then
								p_freeze=sec(3)
								del(bullets,b)
							end
						end
					}
				
					if self.f then 
						obj.dx=-3 
						obj.x=self.x
					end

					add(bullets,obj)
					
					
					chg_st(self,2)
				end
			end
			
			if self.st==2 then
				if self.t>sec(1) then
					local t=tile_attr(self.tx,self.ty,"o",1)
					t.s=rnd_table(bush_sprites)
					del(actors,self)
					
					local loc=get_rndtile(1)
					add_sniper(loc.tx,loc.ty)
				end
			end
		end,
		draw=ef
	}
	
	local et={o=1}
	local wt={o=1}
	
	if tx+1<map_tilew then et=grid[tx+1][ty] end
	if tx-1>1 then wt=grid[tx-1][ty] end

	if et.o!=1 and wt.o!=1 then
		if yesno() then obj.f=true end
	else
		if et.o==1 then 
			obj.f=true
		end
	end
	
	obj.x,obj.y=tile_to_px(tx,ty)
	tile_attr(tx,ty,"f",obj.f)
	tile_attr(tx,ty,"o",5)

	add(actors, obj)
end


-- #hugger
function add_hugger(tx,ty)
	local obj={
		id=1,
		tx=tx,ty=ty,dx=0,dy=0,
		flip=false,
		detect=50,
		wander_spd=.7,
		chase_spd=1.3,
		hbox={x=4,y=6,w=8,h=5},
		st=0,t=1,
		chase=false,
		navpath={},
		tile={},
		anim=hug_anim,
		update=function(self)
			if self.st==2 then
				if in_range(p_cx,p_cy, self.cx,self.cy, 40) and not self.chase then
					chg_st(self,4)
				end
			end

			alien_upd(self)

			if self.tile.o==4 then
				tile_attr(self.tx,self.ty)
				add_alien(self.tx,self.ty) 
				del(actors,self)
			end
		end,
		draw=function(self)
			if self.st!=99 then
				if self.st==2 or self.st==4 then 
					self.spr=anim(self.anim)
				else
					self.spr=anim(self.anim,true)
				end
				spr(self.spr,self.x,self.y,2,2,self.flip)
			else
				spr(44,self.x,self.y,2,2)
			end
		end
	}
	
	obj.x,obj.y=tile_to_px(tx,ty)
	obj.cx=obj.x+8
	obj.cy=obj.y+8

	add(actors, obj)
end

-- #alien
function add_alien(tx,ty)
	local obj={
		id=2,
		tx=tx,ty=ty,dx=0,dy=0,
		flip=false,
		hbox={x=4,y=4,w=8,h=8},
		st=0,t=1,
		detect=50,
		wander_spd=.5,
		chase_spd=1.1,chase=false,
		navpath={},
		bait=false,
		anim={l={128,130,132,130},f=1,r=8},
		update=function(self)
			if self.st<10 then
				if in_range(p_cx,p_cy, self.cx,self.cy, 60) and not self.chase then
					chg_st(self,4)
				end
			end
		
			alien_upd(self)
			
			if self.st==10 then
				local heading   = atan2(self.bait.x-self.x, self.bait.y-self.y) 
				self.dx,self.dy = dir_calc(heading, 1)
				self.flip=s_flip(heading)
				self.chase=false
				
				chg_st(self,11)
			end
			
			if self.st==11 then
				if not in_range(self.bait.x,self.bait.y, self.cx,self.cy, 12) then
					if not blocked(self.x,self.y, self.dx,self.dy, self.hbox) then
						self.x+=self.dx
						self.y+=self.dy
					end
				end
				
				if self.t>=self.bait.release then
					self.bait=false
					chg_st(self,0)
				end
			end
			
			
		end,
		draw=function(self)
			if self.st!=99 then
				if self.st==2 or self.st==4 then 
					self.spr=anim(self.anim)
				else
					self.spr=anim(self.anim,true)
				end
				spr(self.spr,self.x,self.y,2,2,self.flip)
			else
				spr(44,self.x,self.y,2,2)
			end
		end
	}
	
	obj.x,obj.y=tile_to_px(tx,ty)
	obj.cx=obj.x+8
	obj.cy=obj.y+8
	
	if tmo then
		obj.chase_spd=1.3
		obj.detect=60
	end

	add(actors, obj)
end


-- #walker
function alien_upd(self)
	if self.st==99 and self.t>sec(3) then
		if self.id==1 and level_id==3 then
			h_kills+=1 
			if h_kills==h_eggs then unlock(3) end
		end
		del(actors,self)
		return
	end
	
	-- id:1=hugger,2=alien
	local id=self.id
	local dest={}
	
	self.cx=self.x+8
	self.cy=self.y+8
	self.tx,self.ty=px_to_tile(self.cx,self.cy)
	self.tile=get_tile(self.tx,self.ty)

	if self.st<99 then
		if in_range(p_cx,p_cy, self.cx,self.cy,9) then
			chg_st(self,98)
			-- #dead
			mini_mode=false
			blood_t=sec(5)
			gt=0
			music(-1)
			tkr("game over;press z to continue",true)
			gameover=1
			pf_list={}
			p_spr=46
		end
	end


	if self.st==0 then
		self.chase=false
		self.speed=self.wander_spd
		self.wpcount=3
		
		if self.t<2 then
			local near=false

			if id==1 then
				near=find_nearest(self.x,self.y, filter_tiles(4))
				self.wpcount=5
			end

			if not near then 
				near={tx=self.tx,ty=self.ty}
				while near.tx==self.tx and near.ty==self.ty do
					near=get_rndtile(0) 
				end
			end

			self.navpath,self.endpoint,self.waypoint=pathfind(self.tx,self.ty, near.tx,near.ty)
		end
		
		if self.t>sec(2) then
			chg_st(self,1)
		end
	end
	
	
	if self.st==1 then
		self.dest=pf_list[self.navpath[self.waypoint]]
		
		if not self.dest then
			chg_st(self,0)
		else
			self.dest.x,self.dest.y=tile_to_px(self.dest.tx,self.dest.ty)	

			local heading   = atan2(self.dest.x-self.x, self.dest.y-self.y) 
			self.dx,self.dy = dir_calc(heading, self.speed)
			self.flip=s_flip(heading)

			chg_st(self,2)
		end
	end
	
	
	if self.st==2 then
		self.x+=self.dx
		self.y+=self.dy
		
		if self.chase and not in_range(p_cx,p_cy, self.cx,self.cy, self.detect+15) then
			self.chase=false
			self.speed=self.wander_spd
			self.wpcount=rand(3,2)
		end
		local r=7
		if self.tx==p_tx and self.ty==p_ty then r=1 end
		
		
		if in_range(self.cx,self.cy, self.dest.x+8,self.dest.y+8, r) then
			self.waypoint+=1
			self.wpcount-=1

			if self.waypoint>#self.navpath then
				chg_st(self,0)
			else
				if self.wpcount==0 then
					chg_st(self,3)
				else
					chg_st(self,1)
				end
			end
		end
		
	end
	
	
	if self.st==3 then
		if in_range(p_cx,p_cy, self.cx,self.cy, self.detect) then
			chg_st(self,4)
		else
			if self.t>sec(2.5) then
				if id==1 then
					local tile=get_tile(self.endpoint.tx,self.endpoint.ty)
					if tile.o==4 then
						self.wpcount=rand(6,2)
						chg_st(self,1)
					else
						chg_st(self,0)
					end
				end

				if id==2 then
					self.wpcount=rand(3,2)
					chg_st(self,1)	
				end
			end
		end
	end
	
	
	if self.st==4 then
		self.navpath,self.endpoint,self.waypoint=pathfind(self.tx,self.ty, p_tx,p_ty)	
		self.speed=self.chase_spd
		self.wpcount=99
		self.chase=true
		chg_st(self,1)
	end
end


-- #map
-- 0=empty;1=wall;2=spawn;3=egg;4=body;5=sniper;6=beacon;7=bomb;8=detonator;9=queen;98=jones;99=grass
function draw_map()
	function grass() 
		pal(11,lvl.colors[1])
		pal(3,lvl.colors[2])
	end
	
	
	for x=1,map_tilew do
		for y=1,map_tileh do
			local plot=grid[x][y]
			local px,py=tile_to_px(x,y)
			
			if in_range(px,py, p_cx,p_cy, 80) then
				grass() 
				if plot.o==1 then
					spr(plot.s, px, py, 2,2)
				end
				
	            if plot.o==3 then
					spr(plot.s,px,py,2,2)
				end
	            
	            if plot.o==5 then
					spr(42,px,py, 2,2, plot.f)
				end
				
				if plot.o==99 then
					spr(plot.s,px,py,2,1)
				end
				pal()
				
	            
	            if plot.o==7 then
	            	if plot.bomb_st==1 then plot.bomb_st=0 pal(12,8) end
	                spr(110, px,py, 2,2)
					pal()
	            end
	            
	            if plot.o==8 then
	            	if det_st==1 then pal(12,8) end
	                if det_st<3 then spr(108, px,py, 2,2) end
					pal()
	            end
				
				if plot.o==4 then
					spr(9,px,py+3,2,1)
				end
	            
				
					
				if plot.o==6 then
					if tran_st>0 then pal(12,8) pal(13,8) end
					spr(12,px,py,2,2) pal()
				end
				
				if plot.o==98 then
					spr(38,px,py,2,2)
				end
				
				if plot.o==9 then
					pal(11,1) pal(3,1)
					zspr(42,2,2,px-16,py-8, 2, 1) pal()
				end
				
			end
			
			--rect(px,py,px+16,py+16,5)
		end
	end

	grass()
	for m=0,map_tileh do
		spr(3, -15, (16*m), 2,2)
		spr(1, map_wpx, (16*m), 2,2)
	end
	
	for m=-1,map_tilew do
		spr(5, (16*m), -15, 2,2)
		spr(3, (16*m),map_hpx, 2,2)
	end
	
	pal()

end


function gen_map(w,h)
	map_w,map_h=w,h
	map_wpx,map_hpx=map_w*128,map_h*128
	map_tilew,map_tileh=map_w*8,map_h*8
	grid={}
	pf_list={}
	
	for x=1,map_tilew do
		grid[x]={}
		
		for y=1,map_tileh do
			grid[x][y]={
				tx=x,ty=y,
				n=0,f=0,g=0,h=0,p=0,status=0,
				o=0,s=0,
				w=true --is tile empty?
			}
		end
	end

	for mx=1,map_w do
		for my=1,map_h do
			local lx,ly=0,0
			
			while (lx==0 and ly==0) or (lx==1 and ly==0) do
				lx=rand(14,0)
				ly=rand(2,0)
			end
				
			create_screen(mx,my, lx,ly)
			
		end
	end
	
	
	if finale then
		local qx=map_w
		local qy=rand(map_h)
		local ps_x=1
		local ps_y=rand(map_h)
		
		if map_h>map_w then
			qx=rand(map_w)
			qy=map_h
			ps_x=rand(map_w)
			ps_y=1
		end

		create_screen(ps_x,ps_y, 0,0)
		create_screen(qx,qy, 1,0)
	else
		create_screen(rand(map_w),rand(map_h), 0,0)
	end

	local n=1
	local snipers={}
	for x=1,map_tilew do
		for y=1,map_tileh do
			local plot=grid[x][y]
			
			pf_list[n]=plot
			plot.n=n
			n+=1
			
			if plot.o==5 then add(snipers,plot) end
		end
	end
    
    if #snipers>0 then
		for n=1,lvl.snipers do
			local t=rnd_table(snipers)

            add_sniper(t.tx,t.ty)
            del(snipers,t)
		end

		for k,t in pairs(snipers) do
			grid[t.tx][t.ty].o=1
			grid[t.tx][t.ty].s=rnd_table(bush_sprites)
		end
	end

    if finale then
    	add_tiles(lvl.bombs, 2,7, 256,256,function(tx,ty)
			tile_attr(tx,ty, "bomb_st", 0)
		end)
		
		add_tiles(1, 0,98, 1,256)
    end

    add_tiles(lvl.bodies, 0,4, 100,70)
    add_tiles(lvl.eggs, 2,3, 130,130, function(tx,ty)
		tile_attr(tx,ty, "s", 14)
	end)
	lvl.eggs+=map_eggs
    
	local ac=0
	while ac<lvl.aliens do
		local t=get_rndtile(0)
		
		if not in_range(t.x,t.y, p_cx,p_cy, 150) then
			add_alien(t.tx,t.ty)
			ac+=1
		end
	end
    
    
	local empty=filter_tiles(0)
	local half=flr(map_tilew*map_tileh*.2)
	for n=0,half do
		local t=rnd_table(empty)
		t.o=99
		if yesno() then t.s=7 else t.s=23 end
		t.h=rand(2)
	end
	
end


bush_sprites={1,3,5,40,72}
function create_screen(mx,my, lx,ly)
	function read_spritelayout(sprx,spry)
		local ox=sprx*8
		local oy=112+(spry*8)
		local set={}

		for sx=0,7 do
			local pxx=sx+1
			set[pxx]={}

			for sy=0,7 do
				local pxy=sy+1
				set[pxx][pxy]=sget(sx+ox,sy+oy)
			end
		end

		return set
	end
	
	
	local smap=read_spritelayout(lx,ly)
	for spx=0,7 do
		for spy=0,7 do
			local tilex=spx+1 + (mx-1)*8
			local tiley=spy+1 + (my-1)*8
			local pxc=smap[spx+1][spy+1]
			local tile={o=0,w=true}
			local bspr=rnd_table(bush_sprites)
			
			--bush/rock wall
			if pxc==11 or pxc==3 or pxc==6 then 
				tile.o=1
				tile.s=bspr
				tile.w=false
				
				if pxc==6 then tile.s=rnd_table({76,78}) end
			end

			-- sniper/bush
			if pxc==3 and lvl.snipers>0 then 
				tile.o=5
				tile.s=bspr
				tile.w=false
			end
			
			
			if pxc==12 then tile.o=6 end -- beacon
			if pxc==15 then tile.o=2 end -- spawn
			
			-- egg
			if pxc==2 then 
				tile.o=3
				tile.s=14
				map_eggs+=1
			end
			
			-- detonator
			if pxc==14 then 
				tile.o=8
				det_st=0
				det_t=0
			end
			
			-- queen
			if pxc==9 then tile.o=9	end
			
			-- player
			if pxc==8 then
				p_x,p_y,p_cx,p_cy=tile_to_px(tilex,tiley)
				p_tx,p_ty=tilex,tiley
			end
			
			for k,v in pairs(tile) do grid[tilex][tiley][k]=v end

		end
	end	
end




-- #intro
function intro_init()
	function intro_drw()
		fd_upd() 
		cprint("alien harvest v1.4;(c)brian vaughn, 2017;;design+code;brian vaughn;@morningtoast;;music;brian follick;@gnarcade_vgm;;animation;@pineconegraphic", 8, fd_c)
		if gt==sec(3.5) then fd_out() end
	end
    
    function p2()
        fd_init(title_init)
        cart(ef,function()
            fd_upd()
            cprint("use headphones;for best experience", 40, fd_c)
            if gt==sec(2.25) then fd_out() end
        end)
    end
    
    fd_init(p2)
	music(0,4000)
	
	cart(ef,intro_drw)
end


-- #story
function story_init()
	local sx=1
	local lspr=14
	local al={l={128,130,132,130},f=1,r=8}
	local hugspr=anim(hug_anim,true)
	local alspr=anim(al,true)

    fd_init()

	function story_upd()
		if btnzp or gt>sec(12) then 
			start_init()
			fp=false
		end

		if gt>sec(3) then
			lspr=anim(hug_anim)
			if sx>=80 then lspr=anim(al) end
			
			sx=min(sx+.5,130)
		end
        
        fd_upd()

	end 

	function story_drw()
		cprint("dylan burke is finishing the;job his father failed to;complete on lv-426.;;he must be stopped.;;;explore planets and collect;alien eggs before burke can;get to them.",8, fd_c)
		palt(2,true)
		spr(lspr,sx,105,2,2)
		if sx<80 then spr(9, 80,111,2,1) end
		pal()
	end


	cart(story_upd,story_drw)
end





-- #title
fp=true
hug_anim={l={160,162,164,162},f=1,r=8}
function title_init()
	finale=false
	level_id=0
	p_eggs=0
	map_eggs=0
	gameover=0
	grid={}
	blood={}
	levels={}
	achv_c=0
	bishop=true
	
	
	local ty=-8
	local hugspr=anim(hug_anim,true)
	local hugx=-16
	local gst=1

	fd_init()

	function title_upd()		
		if btnzp then
			if gst==1 then
				tmo=false
				countdown=sec(40)
				tran_w=5
				quota=12
				
				if fp then story_init() else start_init() end 
			end

			if gst==3 and tm>0 then
				tmo=true
				countdown=sec(30)
				quota=20
				tran_w=7
				fp=false
				
				start_init()
			end
			
			if gst==2 then help_init() end
			if gst==4 then achv_init() end

		end

		if btnp(2) then gst-=1 end
		if btnp(3) then gst+=1 end
		
		if gst>4 then gst=1 end
		if gst<1 then gst=4 end
        
		
		if gt>sec(1.5) then fd_upd() end
		hugspr=anim(hug_anim)
	end 
	
	function title_drw()
		local label="normal mode"
		
		if gst==2 then label="how to play" end
		if gst==3 then if tm>0 then label="terror mode" else label="mode locked" end end
		if gst==4 then label="achievements" end
		
		
		ty=min(60,ty+1)
		cprint("a l i e n",ty,12)
		cprint("harvest",68,fd_c)
		
		if gt>sec(2.2) then
			spr(90,60,94)
			cprint(label,100,6)
			spr(90,60,103,1,1,false,true)
		end
		palt(2,true)
		
		if gt>sec(4) then 
			hugx=min(135,hugx+.5) 
			spr(hugspr,hugx,80,2,2)
		end
	end
	
	cart(title_upd,title_drw)
end

-- dget() 0=terror;1=no weapons;2=all bodies;3=kill huggers;4=save jones;5=ripley
function achv_init()
    function achv_drw()
        cprint("achievements",10,12)
        
        if tm>0 then tc1=10 else tc1=1 end
        if dget(1)>0 then tc2=10 else tc2=1 end
        if dget(2)>0 then tc3=10 else tc3=1 end
        if dget(3)>0 then tc4=10 else tc4=1 end
        if dget(4)>0 then tc5=10 else tc5=1 end
		if dget(5)>0 then tc5=10 else tc5=1 end
        
        cprint("terror mode",30,tc1)
        cprint("bishop's dozen",40,tc2)
        cprint("bone collector",50,tc3)
        cprint("no hugs",60,tc4)        
        cprint("save jonesy",70,tc5)
		cprint("ripley's revenge",80,tc5)
        cprint("see manual for details",100,7)    
    end

    cart(function() if btnzp then title_init() end end,achv_drw)
end

function unlock(id)
	achv_c+=1
	local c=dget(id)
	if c<1 then
		dset(id,1)
		sfx(23)
	end
end

-- #help
function help_init(auto)
	function help_upd()
		if btnzp then cart(help_last, help_p2) end
	end
	
	function help_last()
		if btnzp then title_init() end
	end
	
	function help_p1()
		palt(2,true)
		spr(14, 5,6, 2,2)
		print("explore planets until\nyou find and collect\n12 alien eggs", 26,8, 7)
		
		spr(12, 5,34, 2,2)
		print("wait on beacon when\nall eggs are gone\nto go to next planet",26,34, 7)
		
		spr(9, 6,62, 2,1)
		print("search bodies to\nequip weapons\n\n\n\n\142 or z for map scan\n\n\151 or x to use weapon", 26,60,7)
				
		
		
		pal()
		rect(0,0,127,127,12)
		rect(2,2,125,125,12)
	end
	
	function help_p2()
		palt(2,true)
		spr(64, 7,8, 2,2)
		print("gun has one shot.\nauto-aims at aliens", 28,8, 7)

		spr(96, 7,30, 2,2)
		print("bait will distract\nlarge aliens", 28,30,7)
		

		cprint("avoid aliens", 52, 8)

		spr(160, 6,60, 2,2) 
		print("facehuggers find bodies\nto become aliens",28,62, 7)
		
		spr(128, 5,80, 2,2) 
		print("aliens search and chase\nwhen you are near",28,80, 7)

		
		spr(42, 6,100, 2,2) 
		print("jungle alien attack\nparalyzes. invincible.",28,100, 7)

		pal()
		
		rect(0,0,127,127,12)
		rect(2,2,125,125,12)
	end
	
	cart(help_upd, help_p1)
end




-- #finale
function finale_init()
    finale=true
    fd_init()

    function finale_upd()
        fd_upd()
        if btnzp then start_init() end
    end
    
    
    function finale_drw()
        cprint("with burke's plans ruined you;must now eliminate the source.;;the queen.;;travel to pco-8 and blow it up.;;it's the only way to stop;this nightmare once and for all.",8, fd_c)
        
        if gt>sec(3) then cprint("press z to continue",100,6) end
    end


    cart(finale_upd,finale_drw)
end


-- #victory
function vic_init()
    fd_init()
    music(-1)
	music(0,2000)

	if tm<1 then 
		tm=1
		unlock(0)
	end
	
	if tmo then unlock(5) end
	if jones then unlock(4) end
	if bishop then unlock(1) end

    function vic_upd()
        if btnzp and gt>sec(2) then 
        	if achv_c>0 then
        		fd_init()
				achv_c=0
        		cart(vic_upd,vic_unlock)
        	else
        		title_init() 
        	end
        end
    end
    
    function vic_drw()
		local tc=fd_c
    	if gt>sec(2.5) then
    		fd_upd()
			if fd_s==2 and fd_c==7 then tc=12 end

			cprint("mission accomplished",10, tc)
			cprint("burke and the company have;been stopped once again.;but for how long?;;;;;press z to return home;;;",30, fd_c)
		end
		
		spr(14,55,55,2,2)
	end

	function vic_unlock()
		fd_upd()
		cprint("achievement unlocked",40, fd_c)
    end


    cart(vic_upd,vic_drw)	
end




-- #loop
cartdata("ahmt2017")

function ef() end
function cart(u,d) cart_upd,cart_drw=u,d gt=0 end

function _init()
	tm=dget(0)

	intro_init()
end


function _update60()
	btnl=btn(0)
	btnr=btn(1)
	btnu=btn(2)
	btnd=btn(3)
	btnzp=btnp(4)
	btnxp=btnp(5)
	
	cart_upd()

	gt=min(25000,gt+1)
end


function _draw()
	cls()
	cart_drw()
	
	
end





-- #utilities
function chg_st(o,ns) o.t=0 o.st=ns end
function rand(x,n) n=n or 1 return flr(rnd(x))+n end
function sec(f) return flr(f*60) end
function cprint(s,y,c) 
	local all=split(s)
	for k,t in pairs(all) do
		print(t,64-(#t*2),y,c) 
		y+=8
	end
end
function yesno() if rnd()<.5 then return true end return false end

function s_flip(d)
	if d>.25 and d<.75 then return true end
	return false
end

function random(min,max)
	n=flr(rnd(max-min))+min
	return n
end

function rnd_table(t)
	local r=flr(rnd(#t))+1
	return(t[r])
end

function dir_calc(angle,speed)
	local dx=cos(angle)*speed
	local dy=sin(angle)*speed
	
	return dx,dy
end

function split(s,dc)
	dc=dc or ";"
	local a={}
	local ns=""
	s=s..";"
	
	while #s>0 do
		local d=sub(s,1,1)
		if d==dc then
			add(a,ns)
			ns=""
		else
			ns=ns..d
		end
	
		s=sub(s,2)
	end
	
	return a
end

function few() 
	local c=0
	for k,v in pairs(actors) do if v.id<3 then c+=1 end end
	if c<8 then return true end
	return false
end

--anim(obj,doquickreset)
--obj.r=tick iterator;obj.f=frame position;obj.l=table of sprite ids, each a frame
--reset=force to first frame and reset counter
function anim(obj,reset)
	if reset then
		obj.r=0
		obj.f=1
	else
		obj.r+=1
		if obj.r==8 then
			obj.f+=1
			if obj.f>#obj.l then obj.f=1 end
			obj.r=0
		end
	end
	
	return obj.l[obj.f]
end

--fd_s:0=non;1=fadein;2=hold;3=fadeout
--manually set fd_s=3 in your loop; when fadeout is done, auto-runs func
function fd_init(f)
    fd_cl={0,0,0,0,1,5,13,6,7}
	fd_i=1
	fd_t=0
	fd_s=1
	fd_f=f
    fd_c=0
end
function fd_out() if fd_s<3 then fd_s=3 fd_t=0 end end
function fd_upd()
    if fd_s==1 and fd_t==5 and fd_i<#fd_cl then
        fd_i=min(#fd_cl,fd_i+1)
        fd_c=fd_cl[fd_i]
        fd_t=0
    end
    
    if fd_s==1 and fd_i==#fd_cl then 
    	fd_s=2
    end
    
    if fd_s==3 and fd_t==5 and fd_i>1 then
        fd_i=max(1,fd_i-1)
        fd_c=fd_cl[fd_i]
        fd_t=0
        
        if fd_i==1 then
        	fd_s=0
        	if fd_f then fd_f() end
        end
    end

    if fd_s>0 then fd_t+=1 end
end


function tile_to_px(tx,ty)
	local px=(tx*16)-16
	local py=(ty*16)-16
	local cx=px+8
	local cy=py+8
	return px,py,cx,cy
end

function px_to_tile(pxx,pxy)
	local tx=flr(pxx/16)+1
	local ty=flr(pxy/16)+1
	return tx,ty
end

function get_tile(tx,ty)
	if tx<=map_tilew and tx>0 and ty<=map_tileh and ty>0 then
		local t=grid[tx][ty]

		return t
	end
end

function filter_tiles(o)
	local list={}
	
	for tx=1,map_tilew do
		for ty=1,map_tileh do
			local t=grid[tx][ty]
			t.x,t.y,t.cx,t.cy=tile_to_px(tx,ty)
			t.tx,t.ty=tx,ty
			if t.o==o then
				add(list,t)
			end
		end
	end

	return list
end


function find_nearest(x,y,list)
	local d=9999
	local n=false
	
	for i=1,#list do
		local t=list[i]
		local a = abs(t.x-x)/16
		local b = abs(t.y-y)/16
		local far=sqrt(a^2+b^2)*16

		if far<d then
			d=far
			n=t
		end
	end

	return n,d
end


function in_range(ax,ay, bx,by, rng)
	if abs(ax-bx)<=rng and abs(ay-by)<=rng then
		return true
	else
		return false
	end
end

function tile_attr(tx,ty, key, val)
	if not key then	key="o" val=0 end
	
	grid[tx][ty][key]=val
	return grid[tx][ty]
end

function get_rndtile(occ)
	local list=filter_tiles(occ)
	
	if #list>0 then
		return rnd_table(list)
	end
	
	return false
end

function zspr(n,w,h,dx,dy,dz,fx,fy)
  sx = 8 * (n % 16)
  sy = 8 * flr(n / 16)
  sw = 8 * w
  sh = 8 * h
  dw = sw * dz
  dh = sh * dz

  sspr(sx,sy,sw,sh, dx,dy,dw,dh, fx,fy)
end


function clock(time)
	local s=flr(time/60)
	local m=time%60
	
	while s>=60 do s-=60 end
	
	if m<10 then m="0"..m end
	if s<=0 then
		s="00" 
	elseif s<10 then 
		s="0"..s
	end

	return s..":"..m
end


function add_tiles(q, src, occ, od, pd, f)
	local try=1
	local esc=1
	for i=1,q do
		try,esc=1,1
		
		local sim=filter_tiles(occ)
		while try>0 and esc<50 do
			local t=get_rndtile(src)
            local safe=0
			
			try+=1
			
			if not in_range(t.cx,t.cy, p_cx,p_cy, pd) then
				if #sim>0 then
					for k,s in pairs(sim) do
                        if not in_range(t.cx,t.cy, s.cx,s.cy, od) then
                            safe+=1
                        end
					end                    
                    
                    if safe==#sim then
                        tile_attr(t.tx,t.ty, "o", occ)
                        if f then f(t.tx,t.ty) end
                        try=0
                    end
				else
					tile_attr(t.tx,t.ty, "o", occ)
					if f then f(t.tx,t.ty) end
					try=0
				end
			end
        	
			esc+=1
		end
	end
end

function in_rec(x,y, ox,oy,ow,oh)
	if x>=ox and x<=ox+ow and y>=oy and y<=oy+oh then
		return true
	end
	
	return false
end


function blocked(px,py, dx,dy, hbox)
	function wall(t) 
		if t.o==1 or t.o==5 then return true end
		return false
	end
	
	if  px+hbox.x+dx>0 and
		py+hbox.y+dy>0 and
		px+hbox.x+dx+hbox.w<map_wpx and
		py+hbox.y+dy+hbox.h<map_hpx
	then
	
		local xl = px+hbox.x
		local xr = xl+hbox.w
		local yt = py+hbox.y
		local yb = yt+hbox.h
		
		local t1x,t1y=px_to_tile(xl+dx,yt+dy)
		if wall(get_tile(t1x,t1y)) then
			return true
		else
			local t2x,t2y=px_to_tile(xr+dx,yt+dy)
			if wall(get_tile(t2x,t2y)) then
				return true
			else
				local t3x,t3y=px_to_tile(xl+dx,yb+dy)
				if wall(get_tile(t3x,t3y)) then
					return true
				else
					local t4x,t4y=px_to_tile(xr+dx,yb+dy)
					if wall(get_tile(t4x,t4y)) then
						return true
					end
				end
			end
		end
		
		return false
	else
		return true
	end
end



function pathfind(startx,starty,goaltx,goalty)
	local navpath=find_path({x=startx,y=starty}, {x=goaltx,y=goalty})
	local endpoint=pf_list[navpath[#navpath]]
	
	return navpath,endpoint,1
end


function find_path(start_index,target_index)
	local path={}
	
	for k,v in pairs(pf_list) do
		v.p=0
		v.status=0
	end

	local start=grid[start_index.x][start_index.y]
	local target=grid[target_index.x][target_index.y]
	local open={start.n}
	local closed={}
	
	start.g=0
	start.h=abs(target.x-start.x)+abs(target.y-start.y)
	start.status=1
	
	while #open>0 do
		local current=pf_list[open[1]]
		
        for k,n in pairs(open) do
			if pf_list[n].g+pf_list[n].h<current.g+current.h then
				current=pf_list[n]
			end
		end 
	
		add(closed,current.n)
		del(open,current.n)
		current.status=2

		nchecks={
	        {x=current.tx, y=current.ty-1},
	        {x=current.tx, y=current.ty+1},
	        {x=current.tx+1, y=current.ty},
	        {x=current.tx-1, y=current.ty},        
	    }

        for k,cxy in pairs(nchecks) do
			
			if cxy.x>=1 and cxy.x<=map_tilew and cxy.y>=1 and cxy.y<=map_tileh then
				local neighbor=grid[cxy.x][cxy.y]
				
				if neighbor.n==target.n then
					target.p=current.n
					add(closed,target.n)

					path={}
					local temp={}
					local n=closed[#closed]
					
					while n!=start.n do
						add(temp,n)
						n=pf_list[n].p
					end
					
					for i=#temp,1,-1 do
						add(path,temp[i])
					end
					
					return path
				end
				
				if neighbor.w then
					if neighbor.status==0 then
						neighbor.p=current.n
						neighbor.g=current.g+1
						neighbor.h=abs(target.x-neighbor.x)+abs(target.y-neighbor.y)
						neighbor.status=1
						add(open,neighbor.n)
					elseif neighbor.status==1 then
						if current.g+1<neighbor.g then
							neighbor.p=current.n
							neighbor.g=current.g+1
						end
					end
				end
			end
		end
	end

	return path
end



__gfx__
0000000000000000000000000000000000000000000000000b0000000000000000000000a0a0000aaa0000002222262200000000000c00000000000000000000
000000000000000b00000000000000000000000000300000bbb000000000000000000000a0a0aa0000000000222226220000000000c0c0000000000000000000
000000000000300b00000000000000b0000000000033000bb0b000000000000030000000aa0aaaaa00000000222aaa22000000000ccc00000000000000000000
000000000000300b000300b0000000bb00003300003330bb0bb00030003000303030030000000aaaa0aaa00a22aaaaa200000ddd00c000000000000000000000
0000000000b0030bb00300b0000000bbb0033000003330bb0bb03330000000000000000000aa0aa00aaaaaaa220aa0a2000cc0ddd00000000000000dd0000000
0000000000b0030bb0330bb0003330b0bb033000000000bbbb03303000000000000000000aa000aaa000000022aaaa2200cccc0d00000000000000dd0d000000
0000000000bb030bb0330bb0000330bb0b00000000bbb00bb0330330030000000000000000a00000aa000000222aa22200c0ccc00d00000000000dddd0d00000
00000000000b030bbb00bb000000300bb0bb00000bbbbbbbb00033000030030000000000000a00000aa000002222622200c0cccc0000000000b0dddd0d0d0000
00000000000bb00bbb00bb0000000bbb0bbbb000bb0000bbbbb030303030300300030000bbbbbbb00000000022226222000c0ccccccc00000000ddddd00d00b0
00000000000bb00bbb0bbb000000bb0bb0bbb0000bbbbbb0b0bb03300000000000000000b00000bb000dd0002226222200000000000000000b00dddd0d0d0000
000000003000bb0bbbb0bb000000b0bbb00bbb0000bbbb00bb0bb0300000000000000000b0b0b0bb00dd0d002226222200000d0ddd00000000b00dd0d0d000b0
000000000300bb0bbbb0b000000b0bbb03300b00000000b0bbb0b0000000000030000000b00000bb0dddd0d02226222200000000000000000b0b00dd0d000000
000000000330bbb0bbb00030000bbb0003300000000bb0bb0bb0b0000000000003003000bbbbbbb00ddd0dd02262222200d0ddddddddd00000b000000000b0b0
0000000000330bb0bbbb033000bb000000300000000b0bb000bbb0000000030003030030000000000dddd0d03262232200000000000000000000b000000b0000
0000000000000bbb0bbb0000000000000000000000bbbb00000bb00003000030030303000000000000dddd00326232230c0cc0ccc0cc0c00000000b0b0000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000002333323200000000000000000000000000000000
2222222aa22222222222222aa22222222222222aa222222200900000000000000000000000000000000003333333000022222222222222222222222222222222
222222aaaa222222222222aaaa222222222222aaaa222222090900000000000000003000b0000000000333333333330022222222222222222222222222222222
222222aa00222222222222aa00222222222222aa0022222290090900900000000003330b00030000003333333300333022222222222222222222222222222222
22222a00aa22222222222200aa22222222222200aa22222290090999900000000003330b00330000033330000330033322222222222222222222222222222222
2222aaaa00a2222222222aaa00a22222222222aa0022222200900909000000000b003330033300b0033300bbb033333322222555552222222222222222222222
222aa0aaaaaa22222222aa0aaaa2222222222aa0aa22222209000090900000000bb0033303330bb033000b000b03330322225555555222222222222222222222
222aa0aaaa0a22222222aa0aaa0a222222222aa0aa22222290999909000000000bbbb0330330bbb03300b0330b0000302225005000002222222aaa2222222222
222a000aaa00a2222222a000aa0a222222222aa0aa222222990999990000000000bbbb00330bbbb0000b03330bb00000225505050000525222aaaaa22a0a2222
222aa0a0a0a0a2222222aa0aaaa2222222222a0aaa2222220990090990000000000bbbb0330bbb00000b0330000033302250500005005052220aa0a000a0a222
2222a0aa0aa2222222222a0a0aa22222222222a0aa22222290990990990000000000bbb030bbbb03000bb03330033033220000500005050222aaaa0aa8a0a222
222220aa0aa22222222222aaa0a2222222222aaaa0222222000000000000000033330bbb00bbb03300b00000333333032000005005555050220aa0008a0a8222
22222aa222aa22222222222a0aa2222222222aaaaa2222220000000000000000033330bb0bbb033000bb0bb00000030005005005500005552228800a000a0822
2222aa2222aa22222222222aaa222222222aaa22aaa222220000000000000000003330bb0bb0333000bbbb0bb00000005050bb050b05b0bb2220a00880a0a222
2222aa22222aa2222222222aaa222222222a22222aa2222200000000000000000000030b0b033000b00bb00b0000000050b5005b0b505b5528880a8888088882
22222aa2222222222222222aa22222222222222222aa222200000000000000000000000b0b000000bb0000bb0bbb0000bb00b500b50b50502228828222822222
222222222222222222222222222222222222222222222222000000000000000000000000000000000bb00bbbbb0bb000000b00bb00bbb00b2222222222222222
222aa22222222222222aa22222222222222aa22222222222000000000000000000bbb000bbbb0000aa0770aa1770aa0000000000000000000000000000000000
22aaaa222222222222aaaa222222222222aaaa222222222200000000000000000bbbbb0bbbbbb000aa0770aa1770aa0000006660550000000000000000000000
22aa00222222222222aa00222222222222aa0022222222220000000000000000b0000b0bb000bb000aa00aaaa00aa00000066060555000000000000000000000
2a00aa2aaaaa222222aaaa22222222222aaaaa2aaaaa2222000000000000000000bbb030bbbb0b000aa00aaaa00aa00000066660555000000000006605500000
aa000aaa00aaaaa22a0aaa2aaaaa2222aa000aaa00aaaaa200000d00000d00000bb00b0330bbb00000aaaa00aaaa000000060060055500000006666605550000
aaa0aaaaaaaaaaa2aa000aaa00aaaaa2aaa0aaaaaaaaaaa20000d0d000d0d000bb00bb03300bbb0000aaaa00aaaa000000666666055500000066666605550000
22aaa000aa222222aaa0aaaaaaaaaaa222aaa000aa22222200000ddf0fdd0000bb0bb0003300bb00000aa0770aa0000000600606055500000066666605555000
22000a22a222222222aaa000aa22222222000a22a222222200b0ddddfd0d0000bb0bb0003300bb00000aa0770aa0000000666666055550000066666605555000
220aaa222222222222000a22a2222222220aa022222222220000ddddd00d00b0bb0bb0003300bb00006000000000000000600066055550000666666600555500
22a0a0a22222222222a0a0222222222222a0aa22222222220b00dddd0d0d00000b00bb003300b000060600000000000006666066005555000666666660555500
22aa00aa2222222222aa0aa222222222222aaaa22222222200b00dd0d0d000b000000003300b0000600060000000000006606606605555000666666660555500
22aa222a222222222220aaa22222222222aa2aa2222222220b0b00dd0d0000000000003330000000000000000000000006666666605555000666666660555500
2aa2222aa2222222222aaa222222222222aa22aa2222222200b000000000b0b00330033333333000000000000000000006666666605555000006666660555503
aa02222aaa2222222222a222222222222aa222aa222222220000b000000b0000b003303303000b00000000000000000000066666605555030000000000000000
0aa22222222222222222aa22222222222a22222aa2222222000000b0b000000000b000b0003b00b0000000000000000003000000000000300300030000000300
22222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000030000000030000
222aa222222222a2222aa22222222222222aa2222222222200000000000000000000000000000000000000000000000000000000000000000000000100000000
22aaaa2222222a2222aaaa22222222a222aaaa2222222a22000000000000000000000000000000000000000000000000000c00000000c0000000001110001000
22aa00222222a22222aa002222222a2222aa00222222a222000000000000000000000000000000000000000000000000000c00000000c0000000c01111010100
2a00aa22222a222222a0aa222222a22222a0aa22222a2222000000000000000000000000000000000000000000000000000c00000000c000000c0c0c00111010
aa0000a222a222222aa000a2222a222222aaaa2222a2222200000000000000000000000000000000000000000000000000cccccccccccc0000ccc0c0c0111010
aaa0aa0aaa2222222aaaaa0a22a222222aa000a22a2222220000000000000000000000000000000000000000000000000cc1111111111cc000cccc0c0c011010
20aa00000a222222220a0000aa2222222aaaaa0aa22222220000000000000000000000000000000000000000000000000c111111111111c000ccc0ccc0c01010
200aaaaaa22222222200aaaa0a222222220a0000a22222220000000000000000000000000000000000000000000000000c11aaa11a1a11c000cac0ccc0c01010
2000000aa2222222220a000aa2222222220000aaa22222220000000000000000000000000000000000000000000000000c111111111111c000cac0cac0c01010
20aa00a0022222222200a00a0222222222000a00222222220000000000000000000000000000000000000000000000000c11aa1aa1aa11c000ccc0cac0c01010
20a00a2002222222222000a02222222222a0a000222222220000000000000000000000000000000000000000000000000c111111111111c000cac0ccc0c01010
20a2a22a0222222222220a022222222222aa020aa222222200000000000000000000000000000000000000000000000000cccccccccccc0000ccc0cac0c01010
2a02222aa222222222220a22222222222aa2222aaa222222000000000000000000000000000000000000000000000000000111111111100000ccc0ccc0c01100
aa02222aaa2222222222aa22222222222aa222222aa222220000000000000000000000000000000000000000000000000000cccccccc0000000cc0ccc0c00003
2aa22222222222222222aaa22222222222aa222222222222000000000000000000000000000000000000000000000000000ccc1c1c1cc0003300030ccc0000b0
222222222222222222222222222222222222222222222222000000000000000000000000000000000000000000000000000000000000000000300b0300b00300
22222222ddddd22222222222ddddd22222222222ddddd222000000000000000000000000ddddd000000000000000000000000000000000000000000000000000
2222222ddddddd222222222ddddddd222222222ddddddd2200000000000000000000000ddddddd00000000000000000000000000000000000000000000000000
222222d2000dd0d2222222d2000dd0d2222222d2000dd0d20000000000000000000000d0000dd0d0000000000000000000000000000000000000000000000000
22222222ddd0dddd22222222ddd0dddd22222222ddd0dddd000000000000000000000000ddd0dddd000000000000000000000000000000000000000000000000
22222d2dd00d2d0d22222d2dd00d2d0d22222d2dd00d2d0d000000000000000000000d0dd00d0d0d000000000000000000000000000000000000000000000000
222222dd0dd222d2222222dd0dd22d02222222dd0dd222d20000000000000000000000dd0dd000d0000000000000000000000000000000000000000000000000
222d2ddd0dd22222222d2ddd0dd222d2222d2ddd0dd222220000000000000000000d0ddd0dd00000000000000000000000000000000000000000000000000000
2222ddddd0dd2222d222ddddd0dd22222222ddddd0dd2ddd00000000000000000000ddddd0dd0000000000000000000000000000000000000000000000000000
2d22dddd000dddd0d222dddd000dddd02d22dddd000ddd0200000000000000000d00dddd000dddd0000000000000000000000000000000000000000000000000
2d2dd0d0dd000d0dd22dd0d0dd000d0d2d2dd0d0dd000dd200000000000000000d0dd0d0dd000d0d000000000000000000000000000000000000000000000000
d22dd000dd2222d2d22dd000dd0222d2d22dd220ddd222220000000000000000d00dd000dd0000d0000000000000000000000000000000000000000000000000
2dd22dd00dd222222dd2222dddd222222dd2222d0dd2222200000000000000000dd00dd00dd00000000000000000000000000000000000000000000000000000
22222d2222d2222222222222dd2222222222222dd2dd2222000000000000000000000d0000d00000000000000000000000000000000000000000000000000000
22222dd22dd2222222222222d2222222222222dd222d2222000000000000000000000dd00dd00000000000000000000000000000000000000000000000000000
222222222ddd222222222222dd22222222222dd2222dd2220000000000000000000000000ddd0000000000000000000000000000000000000000000000000000
22222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000
222222f22222222222222f2222222222222222f22222222200000000000000000000000000000000000000000000000000000000000000000000000000000000
2222ff2f2ff222222222f2ff222222222222ff2f2ff2222200000000000000000000000000000000000000000000000000000000000000000000000000000000
2222f222f2222222222f2222ff2222222222f222f222222200000000000000000000000000000000000000000000000000000000000000000000000000000000
222ff2222222222222ff222222222222222ff2222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000
222ffff222ff222222fffff222ff2222222ffff222ff222200000000000000000000000000000000000000000000000000000000000000000000000000000000
222ffffffff0f222222ffffffff0f222222ffffffff0f22200000000000000000000000000000000000000000000000000000000000000000000000000000000
222fffffffff2222222fffffffff2222222fffffffff222200000000000000000000000000000000000000000000000000000000000000000000000000000000
2222fff00ff0f2222222fff00ff0f2222222fff00ff0f22200000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222f2f22f2222222222f2f22f2222222222f2f22f2200000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222f2f22f22222222222f2f22f22222222222f2f22f200000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bb0000bbb00000b00000fffb0000000000600fbbbbb0000000b00000000bfbfb00000bbb00000000b000fffb000000000bbb0000000000000000000000000000
b000000b002200000000ffb0b0000b00000000fb0000000000f300000003fbfb00ff00000b0000b0300003bb00bbbbb000000bbb00603bb00000000000000000
00000000020000b0b300bb0000000000000f00000000000000ffbbbb000bfbf300fb00000bf0fbb0b00000000bffff3000000b6000ffbbbb0000000000000000
00000c00000009b00000ff0000000000006f00000fff00000b0000b000000b0b0003000000bbb00000ffff00000000b0003ffbb000bbbbbb0000000000000000
000800000e0000b00bb00000006f000b006ff00000bb300b0bbbff0003000b0000fb0b00000ff0000006f0000ff00ff00bbff3000fbbbbbb0000000000000000
00000000000020b0bff0bbb000fb3f03b00f60000b0f00fbbffb6ff00fb00000bffbffbbbf6ff00300f6ff0303bfff00bbbffb0003bbbb0b0000000000000000
b000000b000220000f60fffb00f3bf0b000f00b00bf00f0b00f0ff000ff60000bf3f00b0bffff6fb00ff060b000bbbb0bbb0060000bbb00b0000000000000000
bb0000bbb00000b00ff0fffb000f000b0000000000b00b0000300000bbbf00b00b0000b0b000fffb0000000b00000000b6000000000bb0bb0000000000000000
0000006000000b0b0000000b0000000b0b000b000bb00bbb000000000000000000000000000000000000000000000f60000000000bbbbbbb0000000000000000
03000000003fff0b00000b00bbbbb00b0b000b0bbff00fffb030b0000bb00000000b00600bb03b000bbfbbb06f060000bbb3f06000bbbbbb0000000000000000
0b0000b000fbb00b00300b0000ff300b0006f00bbf3000000fbfbfbb0b30f6000b0fbff00bf0bbb00bbf6bb00f0fff0600fff0000006bbbb0000000000000000
0f3fbbf00bfbb0000fbff030000fbb000b0ffb00006000000fbfffb00ff0f0000bfffb000bbbbbb00f36fff00b0fb60000bbbbf00f3bbb6b0000000000000000
0fbb6bf0000b30000bf3f0fbb300f600b3fbf30b00000300bbbf3fb0000b3000003fffb000bbbbb00fb6f000000006f000f000f000fbbbf30000000000000000
0fbfff300bf6bb060bf000fb0000fb00000b000bbff00bfb0000b0b0000bbfbb000b00b003663f0000f6f00000fffff00bbfbbb0000bbbfb0000000000000000
00bf0000000fb30b0b000f600000bb000b000b00bff00bfb0060b0b0bb0fffbb0f00b0000bbbbbb000000000606f0060003ff00000060b0b0000000000000000
b00000000000000b0bb00300000000000b000b00bbb00bb000000000b3000000060000000bbbbbb000b00bb00066000000b00000000000000000000000000000
__label__
bbbbbb0b0bb03300bbbbbb0b0bb03300bbbbbb0b0bb03300bbbbbb0b0bb03300bbbbbb0b0bb03300bbbbbb0b0bb03300bbbbbb0b0bb03300bbbbbb0b0bb03300
0bbbb00bb0bb03000bbbb00bb0bb03000bbbb00bb0bb03000bbbb00bb0bb03000bbbb00bb0bb03000bbbb00bb0bb03000bbbb00bb0bb03000bbbb00bb0bb0300
00000b0bbb0b000000000b0bbb0b000000000b0bbb0b000000000b0bbb0b000000000b0bbb0b000000000b0bbb0b000000000b0bbb0b000000000b0bbb0b0000
00bb0bb0bb0b000000bb0bb0bb0b000000bb0bb0bb0b000000bb0bb0bb0b000000bb0bb0bb0b000000bb0bb0bb0b000000bb0bb0bb0b000000bb0bb0bb0b0000
00b0bb000bbb000000b0bb000bbb000000b0bb000bbb000000b0bb000bbb000000b0bb000bbb000000b0bb000bbb000000b0bb000bbb000000b0bb000bbb0000
0bbbb00000bb00000bbbb00000bb00000bbbb00000bb00000bbbb00000bb00000bbbb00000bb00000bbbb00000bb00000bbbb00000bb00000bbbb00000bb0000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030303003000300000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000003000000000000000000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000
03000303030030000000000000000000000000000000000000000000000000000000000000000000030003030300300000000000000000000000000300000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030030000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000300030300300
30000000000000000000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000003000030030303000
03003000000000000000000000000000000000000000000000000000000000000000000000000000030030000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000b00000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000300000bbb0000000003000b0000000000000000000000000003000b00000000000000b000000000
000000000000000000000000000000000000000000000000033000bb0b000000003330b00030000000000b0000000000003330b000300000000300b000000000
00000000000000000000000000000000000000000000000003330bb0bb000300003330b00330000000000bb000033000003330b003300000000300b000300b00
00000000000000000000000000000000000000000000000003330bb0bb033300b003330033300b0000000bbb00330000b003330033300b000b0030bb00300b00
00000000000000000000000000000000000000000000000000000bbbb0330300bb0033303330bb0003330b0bb0330000bb0033303330bb000b0030bb0330bb00
0000000000000000000000000000000000000000000000000bbb00bb03303300bbbb0330330bbb0000330bb0b0000000bbbb0330330bbb000bb030bb0330bb00
000000000000000000000000000000000000000000000000bbbbbbbb000330000bbbb00330bbbb00000300bb0bb000000bbbb00330bbbb0000b030bbb00bb000
00000000000000000000000000000000000000000000000bb0000bbbbb03030000bbbb0330bbb0000000bbb0bbbb000000bbbb0330bbb00000bb00bbb00bb000
000000000000000000000000000000000000000000000000bbbbbb0b0bb03300000bbb030bbbb030000bb0bb0bbb0000000bbb030bbbb03000bb00bbb0bbb000
0000000000000000000000000000000000000000000000000bbbb00bb0bb03033330bbb00bbb0330000b0bbb00bbb0033330bbb00bbb0333000bb0bbbb0bb000
00000000000000000000000000000000000000000000000000000b0bbb0b000033330bb0bbb0330000b0bbb03300b00033330bb0bbb03300300bb0bbbb0b0000
00000000000000000000000000000000000000000000000000bb0bb0bb0b000003330bb0bb03330000bbb0003300000003330bb0bb033300330bbb0bbb000300
00000000000000000000000000000000000000000000000000b0bb000bbb0000000030b0b03300000bb0000003000000000030b0b03300000330bb0bbbb03300
0000000000000000000000000000000000000000000000000bbbb00000bb0000000000b0b00000000000000000000000000000b0b00000000000bbb0bbb00000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000b000000000000000000000000000000000000000000000000000000000000000000000000bbb000bbbb00003
0003000b0000000000000000000000000300000bbb0000000000000000000000000000000000000000000000000000000000000000000000bbbbb0bbbbbb0000
003330b0003000000000000000000000033000bb0b000000000000000000000000000000000000000000000000000000000000000000000b0000b0bb000bb000
003330b003300000000000000000000003330bb0bb00030000000000000000000000000000000000000000000000000000000000000000000bbb030bbbb0b000
b003330033300b00000000000000000003330bb0bb0333000000000000000000000000000000000000000000000000000000000000000000bb00b0330bbb0000
bb0033303330bb00000000000000000000000bbbb0330300000000000000000000000000000000000000000000000000000000000000000bb00bb03300bbb000
bbbb0330330bbb0000000000000000000bbb00bb03303300000000000000000000000000000000000000000000000000000000000000000bb0bb0003300bb000
0bbbb00330bbbb000000000000000000bbbbbbbb00033000000000000000000000000000000000000000000000000000000000000000000bb0bb0003300bb000
00bbbb0330bbb000000000000000000bb0000bbbbb030300000000000000000000000000000000000000000000000000000000000000000bb0bb0003300bb000
000bbb030bbbb0300000000000000000bbbbbb0b0bb033000000000000000000000000000000000000000000000000000000000000000000b00bb003300b0000
3330bbb00bbb033000000000000000000bbbb00bb0bb030000000000000000000000000000000000000000000000000000000000000000000000003300b00000
33330bb0bbb03300000000000000000000000b0bbb0b000000000000000000000000000000000000000000000000000000000000000000000000033300000000
03330bb0bb033300000000000000000000bb0bb0bb0b000000000000000000000000000000000000000000000000000000000000000000003300333333330000
000030b0b0330000000000000000000000b0bb000bbb0000000000000000000000000000000000000000000000000000000000000000000b003303303000b000
000000b0b000000000000000000000000bbbb00000bb000000000000000000000000000000000000000000000000000000000000000000000b000b0003b00b00
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000aa00000000003030300300030000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000aaaa0000000000000000000000000000000000000000000003000b00000000
00000000000000000000000000000000000000000000000000000000000000000000aa000000000000000000000000000000000000000000003330b000300000
000000000000000000000000000000000000000000000000000000000000aaaaa0aa00a00000000000000003000000000000000000000000003330b003300000
000000000000000000000000000000000000000000000000000000000aaaaa00aaa000aa0000000000000000300300000000000000000000b003330033300b00
000000000000000000000000000000000000000000000000000000000aaaaaaaaaaa0aaa0000000000003000303003000000000000000000bb0033303330bb00
00000000000000000000000000000000000000000000000000000000000000aa000aaa000000000030000300303030000000000000000000bbbb0330330bbb00
000000000000000000000000000000000000000000000000000000000000000a00a0000000000000000000000000000000000000000000000bbbb00330bbbb00
000000000000000000000000000000000000000000000000000000000000000000aaa000000000000000000000000000000000000000000000bbbb0330bbb000
00000000000000000000000000000000000000000000000000000000000000000a0a0a000000000000000000000000000000000000000000000bbb030bbbb030
0000000000000000000000000000000000000000000000000000000000000000aa00aa0000000000000000000000000000000000000000033330bbb00bbb0330
0000000000000000000000000000000000000000000000000000000000000000a000aa00000000000000000000000000000000000000000033330bb0bbb03300
000000000000000000000000000000000000000000000000000000000000000aa0000aa0000000000000000000000000000000000000000003330bb0bb033300
00000000000000000000000000000000000000000000000000000000000000aaa00000aa0000000000000000000000000000000000000000000030b0b0330000
000000000000000000000000000000000000000000000000000000000000000000000aa00000000000000000000000000000000000000000000000b0b0000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000030000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000030003030300300000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000dd000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000dd0d00000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000dddd0d0000000000000000000000300000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000b0dddd0d0d000000000000000000000030030000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000ddddd00d00b000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000b00dddd0d0d000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000b00dd0d0d000b000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000b0b00dd0d00000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000b000000000b0b000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000b000000b000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000b0b000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000b00000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000003000b000000000300000bbb0000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000003330b000300000033000bb0b0000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000003330b00330000003330bb0bb0003000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000b003330033300b0003330bb0bb0333000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000bb0033303330bb0000000bbbb03303000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000bbbb0330330bbb000bbb00bb033033000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000bbbb00330bbbb00bbbbbbbb000330000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000bbbb0330bbb00bb0000bbbbb0303000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000bbb030bbbb030bbbbbb0b0bb033000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000033330bbb00bbb03300bbbb00bb0bb03000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000033330bb0bbb0330000000b0bbb0b00000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000003330bb0bb03330000bb0bb0bb0b00000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000030b0b033000000b0bb000bbb00000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000b0b00000000bbbb00000bb00000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0000000000003000b000000000003000b00000000
000000000000000000000000000000000000000000000000000000000000000000000b0000000000000300b000000000003330b000300000003330b000300000
000000000000000000000000000000000000000000000000000000000000000000000bb000033000000300b000300b00003330b003300000003330b003300000
000000000000000000000000000000000000000000000000000000000000000000000bbb003300000b0030bb00300b00b003330033300b00b003330033300b00
000000000000000000000000000000000000000000000000000000000000000003330b0bb03300000b0030bb0330bb00bb0033303330bb00bb0033303330bb00
000000000000000000000000000000000000000000000000000000000000000000330bb0b00000000bb030bb0330bb00bbbb0330330bbb00bbbb0330330bbb00
0000000000000000000000000000000000000000000000000000000000000000000300bb0bb0000000b030bbb00bb0000bbbb00330bbbb000bbbb00330bbbb00
00000000000000000000000000000000000000000000000000000000000000000000bbb0bbbb000000bb00bbb00bb00000bbbb0330bbb00000bbbb0330bbb000
0000000000000000000000000000000000000000000000000000000000000000000bb0bb0bbb000000bb00bbb0bbb000000bbb030bbbb030000bbb030bbbb030
0000000000000000000000000000000000000000000000000000000000000000000b0bbb00bbb003000bb0bbbb0bb0033330bbb00bbb03333330bbb00bbb0330
000000000000000000000000000000000000000000000000000000000000000000b0bbb03300b000300bb0bbbb0b000033330bb0bbb0330033330bb0bbb03300
000000000000000000000000000000000000000000000000000000000000000000bbb00033000000330bbb0bbb00030003330bb0bb03330003330bb0bb033300
00000000000000000000000000000000000000000000000000000000000000000bb00000030000000330bb0bbbb03300000030b0b0330000000030b0b0330000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbb0bbb00000000000b0b0000000000000b0b0000000
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555
51111111111111111111111111111111111111111111111111111111111111111111111111111111111111111155555555555555555555555555555555555555
51111111111111111111111111111111111111111111111111111111111111111111111111111111111111111155555555555555555555555555555555555555
51cc11cc11111ccc1ccc1ccc1ccc1ccc1cc11ccc1cc111cc1111111111111111111111111111111111111111115555888888855555555555566655555dd55555
5c111c1111111c1c1c111ccc1c1c11c11c1c11c11c1c1c11111111111111111111111111111111111111111111555585555588555555555555565555dd5d5555
5c111ccc11111cc11cc11c1c1ccc11c11c1c11c11c1c1c1111111111111111111111111111111111111111111155558585858855555555555666555dddd5d555
5c1c111c11111c1c1c111c1c1c1c11c11c1c11c11c1c1c1c11111111111111111111111111111111111111111155558555558855555555555655555ddd5dd555
5ccc1cc111111c1c1ccc1c1c1c1c1ccc1c1c1ccc1c1c1ccc11111111111111111111111111111111111111111155558888888555555555555666555dddd5d555
511111111111111111111111111111111111111111111111111111111111111111111111111111111111111111555555555555555555555555555555dddd5555
51111111111111111111111111111111111111111111111111111111111111111111111111111111111111111155555555555555555555555555555555555555
55555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555

__gff__
0000000202000000000000000000000001000002020000000000000000000000000002020000020200000000000000000000020200000202000000000000000000000000020200000000000000000000000000000202000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000070800000000000005060102030405060506030403040506000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000171800000000000015161112131415161516131413141516000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000708000000000000000000000003040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000001718000000000000070800000013140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0708000000000000000000171800000001020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1718000000000000000000000000000011120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000001020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000007080000000000000000000011120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000017180000000000000000000705060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000001715160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000007080000000003040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000007080000000017180800000013140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000017180000000000171800000005060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000070800000000000000000000000015160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000171800000000000000000000000005060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000708000000000015160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000001718000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
01110000267502675026740267402673226732267222672226712267122b7002b7002b7502b7502b7422b72227750277502774027740277322773227722277222771227712003000030024750247502474024720
01110000217502175021740217402173221732217222172221712217122b7002b7002775027750277422772226750267502674026740267322673226722267222671226712207000030029750297502974029720
011100000775507745077450773507755077450774507735077550774507745077350775507745077450773509755097450974509735097550974509745097350a7550a7450a7450a7350a7550a7450a7450a735
011100000f7550f7450f7450f7350f7550f7450f7450f7350f7550f7450f7450f7350f7550f7450f7450f7350e7550e7450e7450e7350e7550e7450e7450e7350e7550e7450e7450e7350e7550e7450e7450e735
010d00000e773007003e6353e62526640266450e7733e6353e6153e6250e7430070026640266453e625007000e773007003e6353e62526640266450e7733e6353e6150e7733e6250e77326625266352664526655
010d00002536525305253652536500300003002036523365253602536526360263652836028365263602636026352263522634226342233602336525360253602535025352253422534225332253322532225322
010d000026365263002636526365003000030025365233652136021365253602536526360263652836028360283522835228342283422a3602a3602a3502a3522a3422a342253602536025352253522534225342
010d00002d3352d3002d3352d3350000028305283352a3352d3302d3352f3302f33528330283352a3302a3302a3322a3322a3322a3322c3302c3352d3302d3302d3322d3322d3322d3322d3322d3322d3322d332
010d00002f3352d3002f3352f33500000283052d3352c3352a3302a3352d3302d3352f3302f3352d3302d3302d3322d3322d3322d3322c3302c3302c3322c3322c3322c332283302833028332283322833228332
0010000014770106001b5001330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000001477000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300003205032050320503205020600026001540032050320503205032050320003200032000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060000074500745007450074501540016400074500745007450074501b300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000361502f1502a150241501c150161500e15008150031500115000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300000565005650036000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600003f4303f4303f4303f4303f4303f4303f4303f6303f6303f6303f6303f6303f6303f6303f6303f6303f6303f6302663026630266302663026630266302663026630067300f730157301c7302873034730
000300001e3502035023350273502e350343502c30032300353002430024300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700002e7503a700336003a75033600336003360000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000002c550000002c550000002c550000003355000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c000007250072501125011250000000000000000000000725007250112501125000000000000000008200072500725011250112500000000000072000c2000725007250112501125000000000000000000000
001000000562005620056200562006620066200662006620076200762008620096200b6300d63010630116401464016640196401c6401f6402264025640286402b6502e6503365035650386503c6603f6603f660
010a00001477014770147701477014770147701477014770147701477014770147701477014770147701477014770147701477014770147701477014770147701477014770147701477014770147701477014770
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060000183311a3411c3511d3611f36121361243602b36030360243602b36030360243062b306303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b0000293502935029352293522934229342293422934229332293322b3502b345273502735524350243552e3502e3502e3502e350223502435027350293502b3502b3502b3502b3502b3502b3502b3502b350
010b00000c0500c0550c0550c05507050070550a0500a0550c0500c0550c0550c05507050070550a0500a0550c0500c0550c0550c05507050070550a0500a0550c0500c0550c0550c05507050070550a0500a055
010b0000070600706507065070650a0600a0650306003065070600706507065070650a0600a0650306003065070600706507065070650a0600a0650306003065070600706507065070650a0600a0650306003065
010b00000e773356053562535635286402864535625356250e773356253563535625286402864535625356350e773356053562535635286402860535625356350e77335625356353562528640286453562535635
010b00000c0500c0550c0550c05507050070550c0500c0550f0500c050070500c0500f0500f05013050130500f0500f0550c0500c05007051070550c0500c0550f0500f05513050130550e0500e0550a0500a055
010b0000293502935029352293522934229342293422934229332293322b3502b3452735027355243502435529350293502735027350243502435026351263502235022350223522235222352223522235222352
010b00003235032350323523235232342323423234232342303322e3322b35029345273502735524350243552e3502e3502e3502e350223502435027350293502b3502b3502b3522b3522b3522b3522b3522b352
010d000006345043051234512345063450430512345123450634504305123451234506345043051234512345063450d3451234515345093450430515345153450934504305153451534509345043051534515345
010d00000b3450430517345173450b3450430517345173450b3450430517345173450b3450430517345173450e3450d3051a3451a3450e3450d3051a3451a3451e3451a345173451434510345123451a34517345
010d00000e773007003e6353e62526640266450e7733e6353e6153e6250e7430070026640266453e625007000e773007003e6353e62526640266450e7733e6353e6153e6250e7430070026640266453e6153e625
010d00000e773007003e6353e62526640266450e7733e6353e6153e6250e7430070026640266453e625007000e773007003e6353e62526640266450e7733e6352661526625266152662526625266352664526655
010d00000e773007003e6353e62526640266450e7733e6353e6153e6250e7430070026640266453e625007000e773007003e6353e62526640266450e7733e6353e6150e7733e6250e77326625266352664526655
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 00024344
02 01034344
00 41424344
01 27294344
02 282a4344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

