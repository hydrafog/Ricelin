
function getEnabled(text) {
  var m = /animations\s*=\s*\{[^}]*?enabled\s*=\s*(\w+)/.exec(text);
  return m ? m[1] : "";
}

function setEnabled(text, literal) {
  var re = /(animations\s*=\s*\{[^}]*?enabled\s*=\s*)(\w+)/;
  if (!re.test(text)) return { text: text, ok: false };
  return { text: text.replace(re, "$1" + literal), ok: true };
}

function getLeafSpeed(text, leaf) {
  var re = new RegExp(
    'hl\\.animation\\(\\{[^}]*?leaf\\s*=\\s*"' +
      leaf +
      '"[^}]*?speed\\s*=\\s*([0-9.]+)',
  );
  var m = re.exec(text);
  return m ? m[1] : "";
}

function setAllSpeeds(text, literal) {
  var n = 0;
  var out = text.replace(/(\bspeed\s*=\s*)[0-9.]+/g, function (_, head) {
    n++;
    return head + literal;
  });
  return { text: out, ok: n > 0, count: n };
}

function getCurvePoints(text, name) {
  var re = new RegExp(
    'hl\\.curve\\(\\s*"' +
      name +
      '"[^)]*?points\\s*=\\s*\\{\\s*\\{\\s*([0-9.-]+)\\s*,\\s*([0-9.-]+)\\s*\\}\\s*,\\s*\\{\\s*([0-9.-]+)\\s*,\\s*([0-9.-]+)\\s*\\}',
  );
  var m = re.exec(text);
  if (!m) return null;
  return [
    parseFloat(m[1]),
    parseFloat(m[2]),
    parseFloat(m[3]),
    parseFloat(m[4]),
  ];
}

function setCurvePoints(text, name, x1, y1, x2, y2) {
  var re = new RegExp(
    '(hl\\.curve\\(\\s*"' +
      name +
      '"[^)]*?points\\s*=\\s*\\{\\s*\\{\\s*)[0-9.-]+\\s*,\\s*[0-9.-]+(\\s*\\}\\s*,\\s*\\{\\s*)[0-9.-]+\\s*,\\s*[0-9.-]+(\\s*\\})',
  );
  if (!re.test(text)) return { text: text, ok: false };
  return {
    text: text.replace(
      re,
      "$1" + x1 + ", " + y1 + "$2" + x2 + ", " + y2 + "$3",
    ),
    ok: true,
  };
}


