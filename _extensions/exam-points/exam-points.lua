local function parse_number(value)
  if value == nil then return nil end
  if type(value) == "number" then return value end
  if type(value) == "string" then
    local n = tonumber(value)
    if n then return n end
  end
  if type(value) == "table" then
    local text = pandoc.utils.stringify(value)
    if text ~= "" then
      local n = tonumber(text)
      if n then return n end
    end
  end
  return nil
end

local function parse_bool(value)
  if value == nil then return false end
  if type(value) == "boolean" then return value end
  if type(value) == "string" then
    local lower = value:lower()
    return lower == "true" or lower == "1" or lower == "yes" or lower == "ja"
  end
  if type(value) == "number" then return value ~= 0 end
  return false
end

local function normalize_lang(lang)
  if not lang then return "en" end
  local code = pandoc.utils.stringify(lang):lower():match("^%s*(.-)%s*$")
  if code == "" then return "en" end
  code = code:gsub("_", "-")
  local primary = code:match("^([a-z][a-z])")
  return primary or "en"
end

local builtin_locale = {
  en = {
    warning_title  = "Check total points!",
    warning_label  = "Warning:",
    invalid_total  = "Point check enabled, but invalid total points (exam.points-total) specified!",
    mismatch_total = "exam.points-total is %s, but total points from tasks are %s.",
    success_total  = "Total points (%s) match the sum of all subquestions \xE2\x9C\x93"
  },
  de = {
    warning_title  = "Achtung: Gesamtpunktzahl pr\xC3\xBCfen!",
    warning_label  = "Warnung:",
    invalid_total  = "Punktekontrolle aktiviert, aber ung\xC3\xBCltige Gesamtpunktzahl (exam.points-total) angegeben!",
    mismatch_total = "exam.points-total ist %s, aber die aus den Aufgaben berechneten Punkte sind %s.",
    success_total  = "Gesamtpunktzahl (%s) stimmt mit der Summe aller Teilaufgaben \xC3\xBC\x62erein \xE2\x9C\x93"
  },
  fr = {
    warning_title  = "V\xC3\xA9rifier le total des points !",
    warning_label  = "Attention :",
    invalid_total  = "Contr\xC3\xB4le des points activ\xC3\xA9, mais le total sp\xC3\xA9cifi\xC3\xA9 (exam.points-total) est invalide !",
    mismatch_total = "exam.points-total est %s, mais le total calcul\xC3\xA9 des t\xC3\xA2ches est %s.",
    success_total  = "Le total des points (%s) correspond \xC3\xA0 la somme de toutes les sous-questions \xE2\x9C\x93"
  },
  it = {
    warning_title  = "Verifica il totale dei punti!",
    warning_label  = "Avviso:",
    invalid_total  = "Controllo dei punti attivato, ma il totale specificato (exam.points-total) non \xC3\xA8 valido!",
    mismatch_total = "exam.points-total \xC3\xA8 %s, ma il totale calcolato \xC3\xA8 %s.",
    success_total  = "Il totale dei punti (%s) corrisponde alla somma di tutte le sotto-domande \xE2\x9C\x93"
  },
  es = {
    warning_title  = "\xC2\xA1Verifique el total de puntos!",
    warning_label  = "Advertencia:",
    invalid_total  = "Control de puntos activado, pero el total especificado (exam.points-total) no es v\xC3\xA1lido.",
    mismatch_total = "exam.points-total es %s, pero el total calculado es %s.",
    success_total  = "El total de puntos (%s) coincide con la suma de todas las subpreguntas \xE2\x9C\x93"
  },
  nl = {
    warning_title  = "Controleer het totaal aantal punten!",
    warning_label  = "Waarschuwing:",
    invalid_total  = "Puntencontrole ingeschakeld, maar het opgegeven totaal (exam.points-total) is ongeldig!",
    mismatch_total = "exam.points-total is %s, maar het berekende totaal is %s.",
    success_total  = "Het totaal aantal punten (%s) komt overeen met de som van alle deelvragen \xE2\x9C\x93"
  },
  pl = {
    warning_title  = "Sprawd\xC5\xBA sum\xC4\x99 punkt\xC3\xB3w!",
    warning_label  = "Ostrze\xC5\xBCenie:",
    invalid_total  = "Kontrola punkt\xC3\xB3w w\xC5\x82\xC4\x85czona, ale podana suma (exam.points-total) jest nieprawid\xC5\x82owa!",
    mismatch_total = "exam.points-total wynosi %s, ale suma punkt\xC3\xB3w z zada\xC5\x84 wynosi %s.",
    success_total  = "\xC5\x81\xC4\x85czna liczba punkt\xC3\xB3w (%s) zgadza si\xC4\x99 z sum\xC4\x85 wszystkich podzada\xC5\x84 \xE2\x9C\x93"
  },
  ru = {
    warning_title  = "\xD0\x9F\xD1\x80\xD0\xBE\xD0\xB2\xD0\xB5\xD1\x80\xD1\x8C\xD1\x82\xD0\xB5 \xD0\xBE\xD0\xB1\xD1\x89\xD0\xB5\xD0\xB5 \xD0\xBA\xD0\xBE\xD0\xBB\xD0\xB8\xD1\x87\xD0\xB5\xD1\x81\xD1\x82\xD0\xB2\xD0\xBE \xD0\xB1\xD0\xB0\xD0\xBB\xD0\xBB\xD0\xBE\xD0\xB2!",
    warning_label  = "\xD0\x92\xD0\xBD\xD0\xB8\xD0\xBC\xD0\xB0\xD0\xBD\xD0\xB8\xD0\xB5:",
    invalid_total  = "\xD0\x9F\xD1\x80\xD0\xBE\xD0\xB2\xD0\xB5\xD1\x80\xD0\xBA\xD0\xB0 \xD0\xB2\xD0\xBA\xD0\xBB\xD1\x8E\xD1\x87\xD0\xB5\xD0\xBD\xD0\xB0, \xD0\xBD\xD0\xBE \xD1\x83\xD0\xBA\xD0\xB0\xD0\xB7\xD0\xB0\xD0\xBD\xD0\xBD\xD0\xBE\xD0\xB5 \xD0\xB7\xD0\xBD\xD0\xB0\xD1\x87\xD0\xB5\xD0\xBD\xD0\xB8\xD0\xB5 (exam.points-total) \xD0\xBD\xD0\xB5\xD0\xB4\xD0\xB5\xD0\xB9\xD1\x81\xD1\x82\xD0\xB2\xD0\xB8\xD1\x82\xD0\xB5\xD0\xBB\xD1\x8C\xD0\xBD\xD0\xBE!",
    mismatch_total = "exam.points-total \xD1\x80\xD0\xB0\xD0\xB2\xD0\xBD\xD0\xBE %s, \xD0\xBD\xD0\xBE \xD1\x80\xD0\xB0\xD1\x81\xD1\x81\xD1\x87\xD0\xB8\xD1\x82\xD0\xB0\xD0\xBD\xD0\xBD\xD0\xBE\xD0\xB5 \xD0\xBE\xD0\xB1\xD1\x89\xD0\xB5\xD0\xB5 \xD0\xBA\xD0\xBE\xD0\xBB\xD0\xB8\xD1\x87\xD0\xB5\xD1\x81\xD1\x82\xD0\xB2\xD0\xBE \xD1\x80\xD0\xB0\xD0\xB2\xD0\xBD\xD0\xBE %s.",
    success_total  = "\xD0\x9E\xD0\xB1\xD1\x89\xD0\xB5\xD0\xB5 \xD0\xBA\xD0\xBE\xD0\xBB\xD0\xB8\xD1\x87\xD0\xB5\xD1\x81\xD1\x82\xD0\xB2\xD0\xBE \xD0\xB1\xD0\xB0\xD0\xBB\xD0\xBB\xD0\xBE\xD0\xB2 (%s) \xD1\x81\xD0\xBE\xD0\xB2\xD0\xBF\xD0\xB0\xD0\xB4\xD0\xB0\xD0\xB5\xD1\x82 \xD1\x81 \xD1\x81\xD1\x83\xD0\xBC\xD0\xBC\xD0\xBE\xD0\xB9 \xD0\xB2\xD1\x81\xD0\xB5\xD1\x85 \xD0\xBF\xD0\xBE\xD0\xB4\xD0\xB7\xD0\xB0\xD0\xB4\xD0\xB0\xD1\x87 \xE2\x9C\x93"
  }
}

local state = {
  points_label = "points",
  points_label_singular = "point",
  total_points = 0,
  lang = "en",
  locale = builtin_locale
}

local function get_message(key)
  local lang_table = state.locale[state.lang] or state.locale.en or builtin_locale.en
  local message = lang_table and lang_table[key]
  if message then return message end
  return (builtin_locale.en and builtin_locale.en[key]) or ""
end

local function parse_string(value)
  if value == nil then return nil end
  local text = pandoc.utils.stringify(value)
  if text == nil then return nil end
  local s = text:match("^%s*(.-)%s*$")
  return s ~= "" and s or nil
end

function Meta(meta)
  local lang = nil
  if meta then
    lang = meta["lang"] or meta.lang
  end
  state.lang = normalize_lang(lang)

  local exam = meta and meta.exam
  if exam then
    -- Support multiple input formats:
    -- 1) String: points-label: "P" (applies to both singular and plural)
    -- 2) Pair/array: points-label: ["Point","Points"] (singular, plural)
    local raw_label = exam["points-label"] or exam["points_label"]
    local function is_pair_sequence(v)
      -- True if v looks like a YAML sequence of two items (each item is not an Inline like Str/Space)
      if type(v) ~= "table" then return false end
      if v[1] == nil or v[2] == nil then return false end
      -- If the elements are Inline elements they have a .t field (e.g., Str, Space).
      -- For a YAML sequence, the elements will themselves be tables without a direct .t tag.
      if type(v[1]) == "table" and v[1].t ~= nil then return false end
      if type(v[2]) == "table" and v[2].t ~= nil then return false end
      return true
    end

    if is_pair_sequence(raw_label) then
      -- array-like; but if there are exactly two elements, they might also represent
      -- a multi-word string that got split. Compare combined vs whole to decide.
      if raw_label[3] == nil then
        local a = parse_string(raw_label[1]) or ""
        local b = parse_string(raw_label[2]) or ""
        local combined = (a .. " " .. b):gsub("%s+", " "):match("^%s*(.-)%s*$")
        local whole = parse_string(raw_label) or combined
        if combined == whole then
          -- treat as single multi-word string
          state.points_label = whole
          state.points_label_singular = whole
        else
          local s = parse_string(raw_label[1])
          local p = parse_string(raw_label[2])
          if s then state.points_label_singular = s end
          if p then state.points_label = p end
        end
      else
        -- more than two elements -> likely inline multi-word string
        local label = parse_string(raw_label)
        if label then
          state.points_label = label
          state.points_label_singular = label
        end
      end
    else
      -- single string or Pandoc inlines: use for both singular and plural
      local label = parse_string(raw_label)
      if label then
        state.points_label = label
        state.points_label_singular = label
      end
    end

    -- explicit singular override (separate key) still takes precedence
    local raw_singular = exam["points-label-singular"] or exam["points_label_singular"]
    local label_singular = parse_string(raw_singular)
    if label_singular then state.points_label_singular = label_singular end
  else
    state.points_label = "points"
    state.points_label_singular = "point"
  end
  return meta
end

local function slugify(text)
  text = text:lower()
  text = text:gsub("[^%w%s%-]", "")
  text = text:gsub("[%s_]+", "-")
  text = text:gsub("-+", "-")
  text = text:gsub("^-", "")
  text = text:gsub("-$", "")
  return text == "" and "section" or text
end

local function parse_points_from_text(text)
  if type(text) ~= "string" then return nil end
  local m = text:match('^%{%.?points=([^}]+)%}$')
  return m and parse_number(m) or nil
end

local function add_suffix(el, points)
  local content = pandoc.List(el.content)
  while #content > 0 and content[#content].t == "Space" do
    content:remove(#content)
  end
  content:insert(pandoc.Space())
  local label = (points == 1) and state.points_label_singular or state.points_label
  -- Build inlines for the suffix: ( <points> <label words> )
  content:insert(pandoc.Str("("))
  content:insert(pandoc.Str(tostring(points)))
  content:insert(pandoc.Space())
  -- split label into words and insert as separate Str + Space inlines
  local first = true
  for w in label:gmatch("[^%s]+") do
    if not first then content:insert(pandoc.Space()) end
    content:insert(pandoc.Str(w))
    first = false
  end
  content:insert(pandoc.Str(")"))
  el.content = content
end

local function process_header(el)
  local points = nil
  local content = pandoc.List(el.content)

  if el.attributes then
    points = parse_number(el.attributes.points)
  end

  if points == nil then
    for i = #content, 1, -1 do
      local raw = pandoc.utils.stringify(content[i])
      local parsed = parse_points_from_text(raw)
      if parsed then
        points = parsed
        content:remove(i)
        if i <= #content and content[i] and content[i].t == "Space" then
          content:remove(i)
        end
        break
      end
    end
    el.content = content
  end

  if points then
    local base_text = pandoc.utils.stringify(el.content)
    if el.identifier and el.identifier:match("%.points") then
      el.identifier = slugify(base_text)
    end

    state.total_points = state.total_points + points
    add_suffix(el, points)
  end

  return el
end

local function is_latex_output(format)
  local fmt = format or FORMAT
  return fmt and (fmt == "latex" or fmt == "beamer" or fmt:match("^latex") ~= nil)
end

local function make_warning_paragraph(message)
  return pandoc.Para({
    pandoc.Strong(get_message("warning_label")),
    pandoc.Space(),
    pandoc.Str(message)
  })
end

local function warning_title()
  return get_message("warning_title")
end

local function make_warning_block(doc, message)
  return quarto.Callout({
    type = "important",
    title = warning_title(),
    content = { make_warning_paragraph(message) }
  })
end

function Header(el)
  return el
end

function Pandoc(doc)
  local lang = nil
  if doc.meta then
    lang = doc.meta["lang"] or doc.meta.lang
  end
  state.lang = normalize_lang(lang)

  local exam = doc.meta and doc.meta.exam
  -- Ensure defaults; Meta() may already have set these
  state.points_label = state.points_label or "points"
  state.points_label_singular = state.points_label_singular or "point"

  -- Also attempt to read labels directly from document metadata to be robust
  if exam then
    local raw_label = exam["points-label"] or exam["points_label"]
    local function is_pair_sequence(v)
      if type(v) ~= "table" then return false end
      if v[1] == nil or v[2] == nil then return false end
      if type(v[1]) == "table" and v[1].t ~= nil then return false end
      if type(v[2]) == "table" and v[2].t ~= nil then return false end
      return true
    end

    if is_pair_sequence(raw_label) then
      if raw_label[3] == nil then
        local a = parse_string(raw_label[1]) or ""
        local b = parse_string(raw_label[2]) or ""
        local combined = (a .. " " .. b):gsub("%s+", " "):match("^%s*(.-)%s*$")
        local whole = parse_string(raw_label) or combined
        if combined == whole then
          state.points_label = whole
          state.points_label_singular = whole
        else
          local s = parse_string(raw_label[1])
          local p = parse_string(raw_label[2])
          if s then state.points_label_singular = s end
          if p then state.points_label = p end
        end
      else
        local label = parse_string(raw_label)
        if label then
          state.points_label = label
          state.points_label_singular = label
        end
      end
    else
      local label = parse_string(raw_label)
      if label then
        state.points_label = label
        state.points_label_singular = label
      end
    end
    local raw_singular = exam["points-label-singular"] or exam["points_label_singular"]
    local label_singular = parse_string(raw_singular)
    if label_singular then state.points_label_singular = label_singular end
  end

  state.total_points = 0
  if doc.blocks then
    doc.blocks = doc.blocks:walk({ Header = process_header })
  end

  if not exam then
    return doc
  end

  local expected = parse_number(exam["points-total"])
  local render_warning = parse_bool(exam["render-warning"])

  if expected == nil then
    local message = get_message("invalid_total")
    io.stderr:write(string.format("\x1b[1;38;5;214m[exam-points-filter] WARNING: %s\x1b[0m\n", message))
    io.stderr:flush()

    if render_warning then
      local warning_block = make_warning_block(doc, message)
      local new_blocks = pandoc.Blocks({warning_block})
      for _, block in ipairs(doc.blocks) do
        new_blocks:insert(block)
      end
      doc.blocks = new_blocks
    end
    return doc
  end

  local mismatch = expected ~= state.total_points

  if mismatch then
    local message = string.format(
      get_message("mismatch_total"),
      tostring(expected), tostring(state.total_points)
    )

    io.stderr:write(string.format("\x1b[1;38;5;214m[exam-points-filter] WARNING: %s\x1b[0m\n", message))
    io.stderr:flush()

    if render_warning then
      local warning_block = make_warning_block(doc, message)
      local new_blocks = pandoc.Blocks({warning_block})
      for _, block in ipairs(doc.blocks) do
        new_blocks:insert(block)
      end
      doc.blocks = new_blocks
    end
  else
    io.stderr:write(string.format(
      "\x1b[37m[exam-points-filter] %s\x1b[0m\n",
      string.format(get_message("success_total"), tostring(expected))
    ))
    io.stderr:flush()
  end

  return doc
end