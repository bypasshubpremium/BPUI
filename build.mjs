import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.dirname(fileURLToPath(import.meta.url));
const srcDir = path.join(root, "src");
const distDir = path.join(root, "dist");

const ORDER = [
    "core", "theme", "icons",
    "components/button", "components/toggle", "components/slider", "components/dropdown",
    "components/input", "components/keybind", "components/colorpicker", "components/text",
    "components/progress", "components/segmented", "components/radio", "components/stepper",
    "components/image", "components/stat", "components/buttonrow", "components/accordion", "components/rangeslider", "components/datatable", "components/icongallery",
    "components/configmanager",
    "components/tab", "components/flyout", "components/window",
    "init",
];

function keyOf(name) { return name.replace("components/", ""); }

function moduleExpr(name) {
    const file = path.join(srcDir, name + ".lua");
    let s = fs.readFileSync(file, "utf8").replace(/^﻿/, "");
    const m = s.match(/^\s*return\s+/);
    if (!m) throw new Error(`${name}.lua must start with \`return function(use, BPUI)\``);
    return s.slice(m[0].length).replace(/\s+$/, "");
}

let out = "";
out += "return (function()\n";
out += "local BPUI = {}\n";
out += "local M, C, L = {}, {}, {}\n";
out += "local function use(name)\n";
out += "    if not L[name] then\n";
out += "        local f = M[name]\n";
out += "        if not f then error(\"BPUI bundle missing module: \" .. name) end\n";
out += "        L[name] = true\n";
out += "        C[name] = f(use, BPUI)\n";
out += "    end\n";
out += "    return C[name]\n";
out += "end\n";

for (const name of ORDER) {
    out += `M[${JSON.stringify(keyOf(name))}] = ${moduleExpr(name)}\n`;
}

out += "return use(\"init\")\n";
out += "end)()\n";

fs.mkdirSync(distDir, { recursive: true });
const target = path.join(distDir, "BPUI.lua");
fs.writeFileSync(target, out);
console.log(`built ${path.relative(root, target)} — ${out.length} bytes, ${out.split("\n").length} lines`);

const examplePath = path.join(root, "example.lua");
if (fs.existsSync(examplePath)) {
    const bundleExpr = out.replace(/^return /, "");
    const exampleTail = fs.readFileSync(examplePath, "utf8").split("\n").slice(1).join("\n");
    const test = `local BPUI = ${bundleExpr}\n${exampleTail}`;
    const testPath = path.join(root, "test.lua");
    fs.writeFileSync(testPath, test);
    console.log(`built ${path.relative(root, testPath)} — ${test.length} bytes`);
}
