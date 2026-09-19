local body = vim.json.encode({
	model = "gemma4",
	prompt = "<|fim_prefix|>@group(0) @binding(0) var<storage, read> input_a : array<f32>;\n@group(0) @binding(1) var<storage, read> input_b : array<f32>;\n@group(0) @binding(2) var<storage, read_write> output : array<f32>;\n\n@compute @workgroup_size(64)\nfn main(@builtin(global_invocation_id) id : vec3<u32>) {\n    let index = id.x;\n    <|fim_suffix|>\n}<|fim_middle|>",
	-- system = "You are an inline code completion tool. The language is WGSL.",
	stream = false,
	think = false,
	keep_alive = "60m",
	options = {
		temperature = 1.0,
		top_p = 0.95,
		top_k = 64,
		num_predict = 128,
	},
})

local out = vim.system({
	"curl",
	"http://localhost:11434/api/generate",
	"-d",
	body,
}):wait()

local response = vim.json.decode(out.stdout).response
print(response)
