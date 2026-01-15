--- GOV.UK Design System Pandoc Filter
---
--- This filter converts Markdown elements to HTML using GOV.UK Design System styling.
--- It handles headers, lists, tables, figures, code blocks, and other common elements,
--- applying appropriate GOV.UK CSS classes and structure.
---
--- @see https://design-system.service.gov.uk/

quarto.doc.add_html_dependency({
	name = "govuk-frontend",
	scripts = {},  -- JS is loaded as ES module in template, not as regular script
	stylesheets = {
        { path = "stylesheets/govuk-frontend.min.css" },      -- GOV.UK Frontend framework
        { path = "stylesheets/quarto-govuk.css" },            -- Custom components (imports from components/)
		{ path = "stylesheets/syntax-highlighting.css" },     -- Code syntax highlighting
	},
	resources = {
		{ name = "assets", path = "assets" },
		{ name = "govuk-frontend.min.js", path = "javascripts/govuk-frontend.min.js" },
		{ name = "govuk-frontend.min.css.map", path = "stylesheets/govuk-frontend.min.css.map" },
		{ name = "govuk-frontend.min.js.map", path = "javascripts/govuk-frontend.min.js.map" },
		-- Component stylesheets (imported by quarto-govuk.css)
		{ name = "components/masthead.css", path = "stylesheets/components/masthead.css" },
		{ name = "components/metadata.css", path = "stylesheets/components/metadata.css" },
		{ name = "components/figure.css", path = "stylesheets/components/figure.css" },
		{ name = "components/line-block.css", path = "stylesheets/components/line-block.css" },
		{ name = "components/code-block.css", path = "stylesheets/components/code-block.css" },
		{ name = "components/lists.css", path = "stylesheets/components/lists.css" }
	},
})

-- ============================================================================
-- Headers
-- ============================================================================

--- Applies GOV.UK heading classes to header elements based on their level.
--- @param el Header The header element to transform
--- @return Header The modified header with GOV.UK classes
function Header(el)
	local class_map = {
		[1] = "govuk-heading-xl",
		[2] = "govuk-heading-l",
		[3] = "govuk-heading-m",
		[4] = "govuk-heading-s",
		[5] = "govuk-body",
		[6] = "govuk-body",
	}

	if el.level >= 7 then
		el.classes = pandoc.List({ "govuk-body" })
	elseif class_map[el.level] then
		el.classes = pandoc.List({ class_map[el.level] })
	end

	return el
end

-- ============================================================================
-- Lists
-- ============================================================================

--- Determines if a list should be rendered in compact mode (no spacing).
--- A list is compact if all items contain only Plain blocks at the start,
--- and any nested lists are also compact.
--- @param items table List of list items (each item is a list of blocks)
--- @return boolean True if the list should be compact
function is_compact(items)
	for _, blocks in ipairs(items) do
		if #blocks == 0 then
			return false
		end

		local first = blocks[1]
		if first.tag ~= "Plain" then
			return false
		end

		-- Check nested lists
		for _, b in ipairs(blocks) do
			if b.tag == "BulletList" or b.tag == "OrderedList" then
				if not is_compact(b.content or b) then
					return false
				end
			end
		end
	end

	return true
end

--- Converts a bullet list to GOV.UK styled HTML.
--- @param el BulletList The bullet list element
--- @return table, boolean List of blocks and false to prevent further traversal
function BulletList(el)
	local spaced = is_compact(el.content) and "" or " govuk-list--spaced"
	local out = {}

	table.insert(out, pandoc.RawBlock("html", '<ul class="govuk-list govuk-list--bullet' .. spaced .. '">'))

	for _, item in ipairs(el.content) do
		table.insert(out, pandoc.RawBlock("html", "<li>"))
		for _, block in ipairs(item) do
			-- Convert Para to Plain to avoid extra <p> tags; keep other blocks intact
			if block.tag == "Para" then
				table.insert(out, pandoc.Plain(block.content))
			else
				table.insert(out, block)
			end
		end
		table.insert(out, pandoc.RawBlock("html", "</li>"))
	end

	table.insert(out, pandoc.RawBlock("html", "</ul>"))
	return out, false
end

--- Converts an ordered list to GOV.UK styled HTML.
--- @param el OrderedList The ordered list element
--- @return table, boolean List of blocks and false to prevent further traversal
function OrderedList(el)
	local spaced = is_compact(el.content) and "" or " govuk-list--spaced"
	local out = {}

	table.insert(out, pandoc.RawBlock("html", '<ol class="govuk-list govuk-list--number' .. spaced .. '">'))

	for _, item in ipairs(el.content) do
		table.insert(out, pandoc.RawBlock("html", "<li>"))
		for _, block in ipairs(item) do
			if block.tag == "Para" then
				table.insert(out, pandoc.Plain(block.content))
			else
				table.insert(out, block)
			end
		end
		table.insert(out, pandoc.RawBlock("html", "</li>"))
	end

	table.insert(out, pandoc.RawBlock("html", "</ol>"))
	return out, false
end

--- Converts a definition list to GOV.UK summary list component.
--- @param el DefinitionList The definition list element
--- @return table, boolean List of blocks and false to prevent further traversal
--- @see https://design-system.service.gov.uk/components/summary-list/
function DefinitionList(el)
	local out = {}
	table.insert(out, pandoc.RawBlock("html", '<dl class="govuk-summary-list">'))

	for _, pair in ipairs(el.content) do
		local term_inlines = pair[1]
		local definitions = pair[2]

		table.insert(out, pandoc.RawBlock("html", '<div class="govuk-summary-list__row">'))

		-- Term
		table.insert(out, pandoc.RawBlock("html", '<dt class="govuk-summary-list__key">'))
		table.insert(out, pandoc.Plain(term_inlines))
		table.insert(out, pandoc.RawBlock("html", "</dt>"))

		-- Definitions (all in a single <dd>)
		table.insert(out, pandoc.RawBlock("html", '<dd class="govuk-summary-list__value">'))
		for _, def_blocks in ipairs(definitions) do
			for _, block in ipairs(def_blocks) do
				if block.tag == "Plain" or block.tag == "Para" then
					table.insert(out, pandoc.RawBlock("html", '<p class="govuk-body">'))
					table.insert(out, pandoc.Plain(block.content))
					table.insert(out, pandoc.RawBlock("html", "</p>"))
				else
					table.insert(out, block)
				end
			end
		end
		table.insert(out, pandoc.RawBlock("html", "</dd>"))

		table.insert(out, pandoc.RawBlock("html", "</div>"))
	end

	table.insert(out, pandoc.RawBlock("html", "</dl>"))
	return out, false
end

-- ============================================================================
-- Paragraphs and Block Elements
-- ============================================================================

--- Wraps paragraph content in GOV.UK body class.
--- @param el Para The paragraph element
--- @return Plain Plain element with wrapped HTML
function Para(el)
	return pandoc.Plain(
		{ pandoc.RawInline("html", '<p class="govuk-body">') } .. el.content .. { pandoc.RawInline("html", "</p>") }
	)
end

--- Converts block quotes to GOV.UK inset text component.
--- @param el BlockQuote The block quote element
--- @return table List of blocks
function BlockQuote(el)
	local out = {}
	table.insert(out, pandoc.RawBlock("html", '<div class="govuk-inset-text">'))
	for _, block in ipairs(el.content) do
		table.insert(out, block)
	end
	table.insert(out, pandoc.RawBlock("html", "</div>"))
	return out
end

--- Converts horizontal rules to GOV.UK section breaks.
--- @param el HorizontalRule The horizontal rule element
--- @return RawBlock The styled section break
function HorizontalRule(el)
	return pandoc.RawBlock(
		"html",
		'<hr class="govuk-section-break govuk-section-break--l govuk-section-break--visible">'
	)
end

--- Converts line blocks to GOV.UK styled divisions with line breaks.
--- @param el LineBlock The line block element
--- @return table List of blocks
function LineBlock(el)
	local out = {}
	table.insert(out, pandoc.RawBlock("html", '<div class="app-c-line-block govuk-body">'))

	for i, line in ipairs(el.content) do
		table.insert(out, pandoc.Plain(line))
		-- Add <br> except after the last line
		if i < #el.content then
			table.insert(out, pandoc.RawInline("html", "<br>"))
		end
	end

	table.insert(out, pandoc.RawBlock("html", "</div>"))
	return out
end

-- ============================================================================
-- Tables
-- ============================================================================

--- Converts tables to GOV.UK table component with proper alignment classes.
--- @param el Table The table element
--- @return table List of blocks representing the HTML table
function Table(el)
	local out = {}

	--- Determines the appropriate GOV.UK class based on cell type and alignment.
	--- @param is_header boolean Whether the cell is a header
	--- @param align string Alignment type (AlignRight, AlignCenter, AlignDefault)
	--- @return string The CSS class string
	local function govuk_class(is_header, align)
		local base = is_header and "govuk-table__header" or "govuk-table__cell"

		if align == "AlignRight" then
			return base .. (is_header and " govuk-table__header--numeric" or " govuk-table__cell--numeric")
		elseif align == "AlignCenter" then
			return base .. " govuk-!-text-align-centre"
		else
			return base
		end
	end

	table.insert(out, pandoc.RawBlock("html", '<table class="govuk-table">'))

	-- Caption
	if el.caption and #el.caption.long > 0 then
		table.insert(out, pandoc.RawBlock("html", '<caption class="govuk-table__caption govuk-table__caption--m">'))
		for _, block in ipairs(el.caption.long) do
			table.insert(out, block)
		end
		table.insert(out, pandoc.RawBlock("html", "</caption>"))
	end

	-- Head
	if el.head and #el.head.rows > 0 then
		table.insert(out, pandoc.RawBlock("html", '<thead class="govuk-table__head">'))
		for _, row in ipairs(el.head.rows) do
			table.insert(out, pandoc.RawBlock("html", '<tr class="govuk-table__row">'))
			for j, cell in ipairs(row.cells) do
				local align = el.colspecs[j] and el.colspecs[j][1] or "AlignDefault"
				local class_attr = govuk_class(true, align)
				table.insert(out, pandoc.RawBlock("html", '<th scope="col" class="' .. class_attr .. '">'))
				for _, block in ipairs(cell.content) do
					table.insert(out, block)
				end
				table.insert(out, pandoc.RawBlock("html", "</th>"))
			end
			table.insert(out, pandoc.RawBlock("html", "</tr>"))
		end
		table.insert(out, pandoc.RawBlock("html", "</thead>"))
	end

	-- Body
	table.insert(out, pandoc.RawBlock("html", '<tbody class="govuk-table__body">'))
	for _, body in ipairs(el.bodies) do
		for _, row in ipairs(body.body) do
			table.insert(out, pandoc.RawBlock("html", '<tr class="govuk-table__row">'))
			for j, cell in ipairs(row.cells) do
				local align = el.colspecs[j] and el.colspecs[j][1] or "AlignDefault"
				local is_row_header = false -- Could be set to (j == 1) for first column headers
				local class_attr = govuk_class(is_row_header, align)

				local tag = is_row_header and "th" or "td"
				local scope = is_row_header and ' scope="row"' or ""

				table.insert(out, pandoc.RawBlock("html", "<" .. tag .. scope .. ' class="' .. class_attr .. '">'))
				for _, block in ipairs(cell.content) do
					table.insert(out, block)
				end
				table.insert(out, pandoc.RawBlock("html", "</" .. tag .. ">"))
			end
			table.insert(out, pandoc.RawBlock("html", "</tr>"))
		end
	end
	table.insert(out, pandoc.RawBlock("html", "</tbody>"))

	table.insert(out, pandoc.RawBlock("html", "</table>"))

	return out
end

-- ============================================================================
-- Links and Media
-- ============================================================================

--- Applies GOV.UK link class to links.
--- @param el Link The link element
--- @return Link The modified link with GOV.UK class
function Link(el)
	el.classes = pandoc.List({ "govuk-link" })
	return el
end

--- Converts figures to GOV.UK figure component with images and captions.
--- @param el Figure The figure element
--- @return table List of blocks representing the HTML figure
function Figure(el)
	local out = {}

	table.insert(out, pandoc.RawBlock("html", '<figure class="app-c-figure" lang="en">'))

	-- Extract the first image
	for _, block in ipairs(el.content) do
		if block.t == "Plain" or block.t == "Para" then
			for _, inline in ipairs(block.content) do
				if inline.t == "Image" then
					local src = inline.src or (inline.target and inline.target[1])
					local title = inline.title or (inline.target and inline.target[2])
					local alt = pandoc.utils.stringify(inline.caption)
					local img =
						string.format('<img class="app-c-figure__image" src="%s" alt="%s" title="%s">', src, alt, title)
					table.insert(out, pandoc.RawBlock("html", img))
				end
			end
		end
	end

	-- Caption
	if el.caption and #el.caption.long > 0 then
		table.insert(out, pandoc.RawBlock("html", '<figcaption class="app-c-figure__figcaption">'))
		table.insert(out, pandoc.RawBlock("html", '<p class="app-c-figure__figcaption-text">'))
		for _, block in ipairs(el.caption.long) do
			table.insert(out, block)
		end
		table.insert(out, pandoc.RawBlock("html", "</p></figcaption>"))
	end

	table.insert(out, pandoc.RawBlock("html", "</figure>"))

	return out
end

-- ============================================================================
-- Code Blocks
-- ============================================================================

--- Wraps code blocks in a container with a copy button.
--- @param el CodeBlock The code block element
--- @return table List of blocks with wrapped code
function CodeBlock(el)
	local out = {}
	table.insert(out, pandoc.RawBlock("html", '<div class="app-example__code">'))
	table.insert(out, el)
	table.insert(out, pandoc.RawBlock("html", "</div>"))
	return out
end

-- ============================================================================
-- Footnotes
-- ============================================================================

--- Storage for footnotes collected during document processing.
local notes = {}

--- Counter for footnote numbering.
local counter = 0

--- Processes footnote references and collects footnote content.
--- @param n Note The footnote element
--- @return RawInline Inline HTML for the footnote reference
function Note(n)
	counter = counter + 1
	local id = "fn" .. counter
	local refid = "fnref" .. counter
	notes[#notes + 1] = { id = id, refid = refid, blocks = n.content }

	return pandoc.RawInline(
		"html",
		string.format(' <sup id="%s"><a href="#%s" class="govuk-link">[footnote %d]</a></sup>', refid, id, counter)
	)
end

--- Renders collected footnotes as GOV.UK styled HTML.
--- @param notes table List of footnote data
--- @return table List of blocks representing the footnotes section
local function render_footnotes(notes)
	local out = {}

	table.insert(out, pandoc.RawBlock("html", "<section>"))
	table.insert(out, pandoc.RawBlock("html", '<h2 class="govuk-heading-m">Footnotes</h2>'))
	table.insert(out, pandoc.RawBlock("html", '<ol class="govuk-list govuk-list--number">'))

	for _, n in ipairs(notes) do
		table.insert(out, pandoc.RawBlock("html", '<li id="' .. n.id .. '">'))
		for _, blk in ipairs(n.blocks) do
			if blk.t == "Para" then
				-- Add back reference link
				table.insert(blk.content, pandoc.Space())
				table.insert(
					blk.content,
					pandoc.RawInline("html", string.format('<a href="#%s" class="govuk-link">↩</a>', n.refid))
				)
			end
			table.insert(out, blk)
		end
		table.insert(out, pandoc.RawBlock("html", "</li>"))
	end

	table.insert(out, pandoc.RawBlock("html", "</ol></section>"))
	return out
end

-- ============================================================================
-- Citations
-- ============================================================================

--- Renders a custom references section from document metadata
--- @param refs table List of references from doc.meta.references
--- @return table List of Pandoc blocks representing the rendered references
local function render_citations(refs)
	local out = {}

	table.insert(out, pandoc.RawBlock("html", '<section><ul class="govuk-list">'))
	table.insert(out, pandoc.RawBlock("html", '<h2 class="govuk-heading-m">References</h2>'))

	for _, ref in ipairs(refs) do
		local id = ref.id or ""
		table.insert(out, pandoc.RawBlock("html", "<li" .. (id ~= "" and (' id="' .. id .. '"') or "") .. ">"))

		local parts = {}

		-- authors
		if ref.author and #ref.author > 0 then
			local names = {}

			for _, a in ipairs(ref.author) do
				if a.family or a.given then
					local name = {}
					if a.family then
						table.insert(name, a.family)
					end
					if a.given then
						table.insert(name, ", " .. a.given)
					end
					table.insert(names, table.concat(name))
				else
					-- fallback: parse unstructured author string manually
					local raw = pandoc.utils.stringify(a)
					for name in string.gmatch(raw, "([^,]+)") do
						local clean = name:gsub("^%s+", ""):gsub("%s+$", "")
						if clean ~= "" then
							table.insert(names, clean)
						end
					end
				end
			end

			if #names == 1 then
				table.insert(parts, pandoc.Str(names[1]))
			elseif #names == 2 then
				table.insert(parts, pandoc.Str(names[1] .. " and " .. names[2]))
			elseif #names > 2 then
				local last = table.remove(names)
				table.insert(parts, pandoc.Str(table.concat(names, ", ") .. ", and " .. last))
			end
		end

		-- year
		if ref.issued and ref.issued["date-parts"] and ref.issued["date-parts"][1] then
			local year = tostring(ref.issued["date-parts"][1][1])
			if #parts > 0 then
				table.insert(parts, pandoc.Space())
			end
			table.insert(parts, pandoc.Str("(" .. year .. ")."))
		end

		-- title (italic)
		if ref.title then
			local t = pandoc.utils.stringify(ref.title)
			if #parts > 0 then
				table.insert(parts, pandoc.Space())
			end
			table.insert(parts, pandoc.Emph(pandoc.Str(t)))
		end

		-- URL / publisher / note
		local url = ref.url or ref.URL or ref.publisher
		if url and type(url) == "string" and url ~= "" then
			if #parts > 0 then
				table.insert(parts, pandoc.Space())
			end
			table.insert(parts, pandoc.Link({ pandoc.Str(url) }, url))
		end

		-- Note field
		if ref.note and type(ref.note) == "string" and ref.note ~= "" then
			table.insert(parts, pandoc.Space())
			table.insert(parts, pandoc.Str("(" .. ref.note .. ")"))
		end

		if #parts > 0 then
			table.insert(out, Para(pandoc.Para(parts)))
		else
			table.insert(out, pandoc.Para({ pandoc.Str(pandoc.utils.stringify(ref)) }))
		end

		table.insert(out, pandoc.RawBlock("html", "</li>"))
	end

	table.insert(out, pandoc.RawBlock("html", "</ul></section>"))
	return out
end

-- ============================================================================
-- Table of Contents
-- ============================================================================

--- Builds a table of contents from document headers.
--- @param blocks table List of document blocks
--- @param max_level number Maximum header level to include in TOC
--- @return Block... Unpacked list of blocks representing the TOC
local function build_toc(blocks, max_level)
	local out = {}

	table.insert(out, pandoc.RawBlock("html", '<ul class="govuk-list">'))

	for _, b in ipairs(blocks) do
		if b.t == "Header" and b.level <= max_level then
			table.insert(out, pandoc.RawBlock("html", "<li>"))
			local link = pandoc.Link(b.content, "#" .. b.identifier, "", pandoc.Attr("", { "govuk-link" }, {}))
			table.insert(out, pandoc.Plain({ link }))
			table.insert(out, pandoc.RawBlock("html", "</li>"))
		end
	end

	table.insert(out, pandoc.RawBlock("html", "</ul>"))

	return table.unpack(out)
end

-- ============================================================================
-- Utility Functions
-- ============================================================================

--- Mixes a colour with white by a given percentage (similar to Sass tint()).
--- @param hex string The base colour in hexadecimal format (e.g. "#1D70B8")
--- @param percent number The percentage of white to mix in (0-100)
--- @return string A new hex colour string representing the tinted result
local function tint(hex, percent)
	local h = hex:gsub("#", "")

	-- Parse hex into RGB components
	local r = tonumber("0x" .. h:sub(1, 2))
	local g = tonumber("0x" .. h:sub(3, 4))
	local b = tonumber("0x" .. h:sub(5, 6))

	-- Mix each channel toward white (255)
	local p = percent / 100
	r = math.floor(r + (255 - r) * p + 0.5)
	g = math.floor(g + (255 - g) * p + 0.5)
	b = math.floor(b + (255 - b) * p + 0.5)

	return string.format("#%02X%02X%02X", r, g, b)
end

-- ============================================================================
-- Main Document Processor
-- ============================================================================

--- Main document processing function. Adds TOC to metadata, appends footnotes and references.
--- @param doc Pandoc The document to process
--- @return Pandoc The modified document
function Pandoc(doc)
	if doc.meta.title or doc.meta.subtitle then
		doc.meta.has_title = true
	else
		doc.meta.has_title = false
	end

	if doc.meta.author or doc.meta.date or doc.meta["date-modified"] then
		doc.meta.has_metadata = true
	else
		doc.meta.has_metadata = false
	end

	-- populate doc.meta.references from bibliography
	doc.meta.references = pandoc.utils.references(doc)

	-- build TOC (headers up to level 2)
	doc.meta.toc_contents = pandoc.MetaBlocks({ build_toc(doc.blocks, 2) })

	if (notes and #notes > 0) or (doc.meta.references and #doc.meta.references > 0) then
		table.insert(
			doc.blocks,
			pandoc.RawBlock(
				"html",
				'<hr class="govuk-section-break govuk-section-break--l govuk-section-break--visible">'
			)
		)
	end

	-- append footnotes
	if notes and #notes > 0 then
		local footnote_blocks = render_footnotes(notes)
		for _, blk in ipairs(footnote_blocks) do
			table.insert(doc.blocks, blk)
		end
	end

	-- append references
	local refs = doc.meta.references or {}
	if #refs > 0 then
		local citation_blocks = render_citations(refs)
		for _, blk in ipairs(citation_blocks) do
			table.insert(doc.blocks, blk)
		end
	end

	return doc
end

-- ============================================================================
-- Filter Configuration
-- ============================================================================

--- Pandoc filter configuration.
--- First pass handles lists (with topdown traversal to prevent child processing).
--- Second pass handles all other elements.
return {
	{
		traverse = "topdown",
		BulletList = BulletList,
		OrderedList = OrderedList,
		DefinitionList = DefinitionList,
		Note = Note,
	},
	{
		Para = Para,
		Header = Header,
		BlockQuote = BlockQuote,
		HorizontalRule = HorizontalRule,
		Link = Link,
		Table = Table,
		LineBlock = LineBlock,
		Figure = Figure,
		CodeBlock = CodeBlock,
		Pandoc = Pandoc,
	},
}
