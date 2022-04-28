using FlatBuffers2
using Test
 
#@testset "PR 234 Arrow.jl: bugfix parsing primitive arrays" begin
#	buf = [
#	    0x14,0x00,0x00,0x00,0x00,0x00,0x0e,0x00,0x14,0x00,0x00,0x00,0x10,0x00,0x0c,0x00,0x08,
#	    0x00,0x04,0x00,0x0e,0x00,0x00,0x00,0x2c,0x00,0x00,0x00,0x38,0x00,0x00,0x00,0x38,0x00,
#	    0x00,0x00,0x38,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
#	    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
#	    0x03,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x02,0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x00,
#	    0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
#	]
#
#	struct TestData <: FlatBuffers.Table
#	    bytes::Vector{UInt8}
#	    pos::Base.Int
#	end
#
#	function Base.getproperty(x::TestData, field::Symbol)
#	    if field === :DataInt32
#	        o = FlatBuffers.offset(x, 12)
#	        o != 0 && return FlatBuffers.Array{Int32}(x, o)
#	    else
#	        @warn "field $field not supported"
#	    end
#	end
#
#	d = FlatBuffers.getrootas(TestData, buf, 0);
#	@test d.DataInt32 == UInt32[1,2,3]
#end

@testset "monsters example" begin
	codegendir = "monster/__codegen/"
	if "FLATC" ∈ keys(ENV)
		mkpath(codegendir)
		flatc = ENV["FLATC"] # path to flatc executable based on https://github.com/jonalm/flatbuffers
		run(`$flatc -o $codegendir --julia monster/monster.fbs`)
		include(joinpath(codegendir, "monster_generated.jl"))
	
		mana = Int16(99)
    	hp = Int16(123)
    	x, y, z = 1f0, 2f0, 3f0
    	color = Foo.Color.Red
    	w1_name = "Sword"
    	w1_damage = Int16(3)
    	w2_name = "Axe"
    	w2_damage = Int16(321)		
    	b = FlatBuffers.Builder()
    	weapon_one_name = FlatBuffers.createstring!(b, w1_name)
    	weapon_two_name = FlatBuffers.createstring!(b, w2_name)
    	pos = Foo.createVec3(b, x,y,z)
    	Foo.WeaponStart(b)
    	Foo.WeaponAddName(b, weapon_one_name) 
    	Foo.WeaponAddDamage(b, w1_damage) 
    	weapon_one = Foo.WeaponEnd(b)
    	Foo.WeaponStart(b) 
    	Foo.WeaponAddName(b, weapon_two_name) 
    	Foo.WeaponAddDamage(b, w2_damage) 
    	weapon_two = Foo.WeaponEnd(b)
    	weapon_vec = [weapon_one, weapon_two]
    	Foo.MonsterStartWeaponsVector(b, length(weapon_vec))
    	for w in Iterators.reverse(weapon_vec)
    	    FlatBuffers.prependoffset!(b, w)
    	end
    	weapons = FlatBuffers.endvector!(b, length(weapon_vec))

		doubles = [1.0, 2.0, 3.0]
		Foo.MonsterStartArrayofdoublesVector(b, length(doubles))
    	for w in Iterators.reverse(doubles)
    	    FlatBuffers.prependoffset!(b, w)
    	end
    	doubles_ = FlatBuffers.endvector!(b, length(doubles))

		shorts = Int16[1, 2, 3]
		Foo.MonsterStartArrayofshortsVector(b, length(shorts))
    	for w in Iterators.reverse(shorts)
    	    FlatBuffers.prependoffset!(b, w)
    	end
    	shorts_ = FlatBuffers.endvector!(b, length(shorts))

		ints = Int32[1, 2, 3]
		Foo.MonsterStartArrayofintsVector(b, length(ints))
    	for w in Iterators.reverse(ints)
    	    FlatBuffers.prependoffset!(b, w)
    	end
    	ints_ = FlatBuffers.endvector!(b, length(ints))

		floats = Float32[1.0, 2.0, 3.0]
		Foo.MonsterStartArrayoffloatsVector(b, length(floats))
    	for w in Iterators.reverse(floats)
    	    FlatBuffers.prependoffset!(b, w)
    	end
    	floats_ = FlatBuffers.endvector!(b, length(floats))

    	Foo.MonsterStart(b)
    	Foo.MonsterAddPos(b, pos)
    	Foo.MonsterAddMana(b, mana)
		Foo.MonsterAddArrayofshorts(b, shorts_)
		Foo.MonsterAddArrayofints(b, ints_)
		Foo.MonsterAddMydouble(b, 1.234)
		Foo.MonsterAddArrayofdoubles(b, doubles_)
		Foo.MonsterAddMyfloat(b, 2.34f0)
		Foo.MonsterAddArrayoffloats(b, floats_)
    	Foo.MonsterAddColor(b, color)
    	Foo.MonsterAddHp(b, hp)
    	Foo.MonsterAddWeapons(b,  weapons)
    	monster = Foo.MonsterEnd(b)
    	FlatBuffers.finish!(b, monster)
	    monsterbuf = FlatBuffers.finishedbytes(b)
	    buf = Vector{UInt8}(monsterbuf) # is this the best way of reading back?
	    monster_ = FlatBuffers.getrootas(Foo.Monster, buf, 0)
	    @test monster_.mana === mana 
	    @test monster_.hp === hp 
	    @test monster_.pos.x === x
	    @test monster_.pos.y === y
	    @test monster_.pos.z === z
	    @test monster_.color === color
	    @test monster_.weapons[1].name === w1_name
	    @test monster_.weapons[2].name === w2_name
	    @test monster_.weapons[1].damage === w1_damage
	    @test monster_.weapons[2].damage === w2_damage
		
		@test monster_.mydouble ===  1.234
		@test monster_.arrayofdoubles[1] ===  doubles_[1]
		@test monster_[Foo.MonsterProperties.arrayofdoubles][1] ===  doubles_[1]

		@test monster_.myfloat ===  2.34f0
		@test monster_.arrayoffloats[1] ===  floats_[1]
		@show monster_.arrayoffloats[1] 
		@show monster_.arrayoffloats[2] 
		@show monster_.arrayoffloats[3] 

		@show monster_.arrayofints[1] 
		@show monster_.arrayofints[2] 
		@show monster_.arrayofints[3] 

		@show monster_.arrayofshorts[1] 
		@show monster_.arrayofshorts[2] 
		@show monster_.arrayofshorts[3] 


		#@test monster_[Foo.MonsterProperties.arrayofdoubles][1] ===  doubles_[1]


	else
		@info "Didn't find flatc executable in as `ENV[\"FLATC\"]`"
	end
end


