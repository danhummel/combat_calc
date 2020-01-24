require 'json'

#basic functions
def roll(qty, die = 6)
	return Array.new(qty) { rand(1..die) }
end

def read_file(filename)
	file = File.read(filename)
	return data = JSON.parse(file)
end

#common die transformations
def reroll(val, arr, mod, goal, die = 6)
	return arr.map { |x| x+mod < goal && val.include?(x) ? rand(1..die) : x }
end

def explode(val, arr, die = 6)
	additional = arr.select { |x| val.include?(x) }
	return arr.concat(additional)
end

def mod_roll(val, arr)
	return arr.map { |x| x += val }
end

#Generic atk_sequence_steps
def atk_step(name, qty, goal, abilities, step, manual_mod = 0)
	arr = roll(qty)
	mod_total = abilities.sum { |x| x["mod"] }

	obj = Abilities.new
	abilities.select { |x| x["step"] == step }.sort_by { |x| x["priority"] }.each do |x|
		arr = obj.public_send(x["method"],arr, mod_total, goal)
	end

	if step == "save"
		return arr.select { |x| x < goal }.count
	else
		return arr.select { |x| x >= goal }.count
	end
end


#army specific
class Abilities
	def reroll_1(arr, mod, goal)
		return reroll([1,2,3],arr,mod,goal)
	end

	def exploding_6s(arr, mod, goal)
		return explode([6],arr)
	end

	def plus_1_to_hit(arr, mod, goal)
		return mod_roll(1, arr)
	end

	def minus_1_to_save(arr, mod, goal)
		return mod_roll(-1, arr)
	end
end

data = read_file("unit.json")
iteration = 100000
dmg = [0,0,0,0,0]

data.each do |unit|
	iteration.times do
		unit["models"].each do |model|
			total_atks = model["qty"]*model["atks"]
			hits = atk_step("To Hit", total_atks,model["to_hit"].to_i,model["abilities"], "hit")
			wounds = atk_step("To Wound", hits,model["to_wound"].to_i,model["abilities"], "wound")
			(2..6).each do |n|
				unsaved = atk_step("To Save", wounds,n,model["abilities"], "save", model["rend"])
				dmg[n-2] += unsaved * model["dmg"]
			end
		end
	end
	puts unit["unit_name"]
end

(2..6).each do |n|
	puts " #{n}+ save: #{dmg[n-2]/iteration.to_f}"
end
puts "\n"
