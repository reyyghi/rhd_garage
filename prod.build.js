const { resolve } = require("path");
const buildPath = resolve(__dirname, "build");

const { build } = require("esbuild");

build({
	entryPoints: ["./client/**/*.ts", "./server/**/*.ts"],
	outdir: resolve(buildPath),
	bundle: true,
	minify: true,
	platform: "browser",
	target: "es2020",
	logLevel: "info",
}).catch(() => process.exit(1));
