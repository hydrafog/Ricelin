function getField(text, name) {
  var re = new RegExp(name + '\\s*=\\s*("[^"]*"|[^,}\\n]*)');
  var m = re.exec(text);
  if (!m) return "";
  var v = m[1].trim();
  if (v.length >= 2 && v.charAt(0) === '"' && v.charAt(v.length - 1) === '"')
    return v.slice(1, -1);
  return v;
}

function setField(text, name, valueLiteral) {
  var re = new RegExp("(" + name + '\\s*=\\s*)("[^"]*"|[^,}\\n]*)');
  if (!re.test(text)) return { text: text, ok: false };
  return { text: text.replace(re, "$1" + valueLiteral), ok: true };
}

function setEnv(text, key, valueRaw) {
  var re = new RegExp(
    '(hl\\.env\\(\\s*"' + escapeRe(key) + '"\\s*,\\s*)"[^"]*"',
  );
  if (!re.test(text)) return { text: text, ok: false };
  return { text: text.replace(re, '$1"' + valueRaw + '"'), ok: true };
}

function setCursorLine(text, theme, size) {
  var re = /setcursor\s+\S+\s+\d+/;
  if (!re.test(text)) return { text: text, ok: false };
  return {
    text: text.replace(re, "setcursor " + theme + " " + size),
    ok: true,
  };
}

function escapeRe(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}


