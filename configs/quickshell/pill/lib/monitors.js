function parseMode(raw) {
  var m = raw.match(/^(\d+)x(\d+)@([\d.]+)Hz$/);
  if (!m) return null;
  return {
    w: parseInt(m[1], 10),
    h: parseInt(m[2], 10),
    hz: Math.round(parseFloat(m[3])),
    raw: raw,
  };
}

function parse(jsonText) {
  var data;
  try {
    data = JSON.parse(jsonText);
  } catch (e) {
    return [];
  }
  if (!Array.isArray(data)) return [];

  return data.map(function (mon) {
    var modes = (mon.availableModes || []).map(parseMode).filter(function (m) {
      return m !== null;
    });
    return {
      name: mon.name,
      width: mon.width,
      height: mon.height,
      refresh: Math.round(mon.refreshRate),
      scale: mon.scale,
      x: mon.x,
      y: mon.y,
      modes: modes,
    };
  });
}

function setMonitor(luaText, output, mode, position, scale) {
  var outRe = new RegExp('output\\s*=\\s*"' + escapeRe(output) + '"');
  var outMatch = outRe.exec(luaText);
  if (!outMatch)
    return { text: luaText, ok: false, error: "output not found: " + output };

  var blockStart = luaText.lastIndexOf("hl.monitor({", outMatch.index);
  if (blockStart === -1)
    return {
      text: luaText,
      ok: false,
      error: "no hl.monitor block for " + output,
    };

  var blockEnd = luaText.indexOf("})", outMatch.index);
  if (blockEnd === -1)
    return {
      text: luaText,
      ok: false,
      error: "unterminated block for " + output,
    };

  var head = luaText.slice(0, blockStart);
  var block = luaText.slice(blockStart, blockEnd);
  var tail = luaText.slice(blockEnd);

  var r1 = replaceField(block, "mode", '"' + mode + '"');
  if (!r1.ok)
    return {
      text: luaText,
      ok: false,
      error: "mode field not found for " + output,
    };
  var r2 = replaceField(r1.text, "position", '"' + position + '"');
  if (!r2.ok)
    return {
      text: luaText,
      ok: false,
      error: "position field not found for " + output,
    };
  var r3 = replaceField(r2.text, "scale", String(scale));
  if (!r3.ok)
    return {
      text: luaText,
      ok: false,
      error: "scale field not found for " + output,
    };

  return { text: head + r3.text + tail, ok: true, error: "" };
}

function replaceField(block, name, value) {
  var re = new RegExp("(" + name + '\\s*=\\s*)("[^"]*"|[^,}\\n]*)');
  if (!re.test(block)) return { text: block, ok: false };
  return { text: block.replace(re, "$1" + value), ok: true };
}

function escapeRe(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}


