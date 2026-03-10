GProfiler.SyntaxColors = {
	keyword    = Color(86, 156, 214),
	library    = Color(78, 201, 176),
	funcCall   = Color(220, 220, 170),
	funcName   = Color(220, 220, 170),
	string     = Color(206, 145, 120),
	comment    = Color(106, 153, 85),
	number     = Color(181, 206, 168),
	operator   = Color(212, 212, 212),
	punctuation= Color(212, 212, 212),
	boolean    = Color(86, 156, 214),
	selfVar    = Color(86, 156, 214),
	nilVal     = Color(86, 156, 214),
	default    = Color(212, 212, 212),
	background = Color(30, 30, 30),
	lineNumber = Color(133, 133, 133),
	lineSep    = Color(70, 70, 70)
}

local keywords = {
	["function"] = true, ["if"] = true, ["then"] = true, ["else"] = true, ["elseif"] = true, ["end"] = true,
	["for"] = true, ["while"] = true, ["do"] = true, ["repeat"] = true, ["until"] = true,
	["local"] = true, ["return"] = true, ["break"] = true, ["in"] = true, ["and"] = true, ["or"] = true, ["not"] = true,
	["goto"] = true, ["continue"] = true
}

local operators = {
	["+"] = true, ["-"] = true, ["*"] = true, ["/"] = true, ["%"] = true, ["^"] = true,
	["="] = true, ["<"] = true, [">"] = true, ["#"] = true, ["!"] = true
}

local function InsertColor(richText, col) richText:InsertColorChange(col.r, col.g, col.b, col.a) end

function GProfiler.SyntaxHighlight(richText, code, startLine)
	local colors = GProfiler.SyntaxColors
	richText:SetText("")
	local i = 1
	local len = #code
	local state = "default"
	local stringChar = ""
	local maxIter = len * 2
	local iter = 0

	local _, totalLines = code:gsub("\n", "\n")
	totalLines = totalLines + 1
	local padWidth = #tostring(totalLines)
	local lineNum = startLine or 1

	local function EmitLineNumber()
		InsertColor(richText, colors.lineNumber)
		local numStr = string.rep(" ", padWidth - #tostring(lineNum)) .. tostring(lineNum)
		richText:AppendText(numStr)
		InsertColor(richText, colors.lineSep)
		richText:AppendText(" | ")
		lineNum = lineNum + 1
	end

	EmitLineNumber()

	while i <= len do
		iter = iter + 1
		if iter > maxIter then break end

		local c = code:sub(i, i)

		if c == "\n" then
			richText:AppendText("\n")
			i = i + 1
			if state == "comment" then state = "default" end
			EmitLineNumber()
		elseif state == "blockcomment" then
			if code:sub(i, i + 1) == "]]" then
				richText:AppendText("]]")
				i = i + 2
				state = "default"
			else
				richText:AppendText(c)
				i = i + 1
			end

		elseif state == "blockstring" then
			if code:sub(i, i + 1) == "]]" then
				richText:AppendText("]]")
				i = i + 2
				state = "default"
			else
				richText:AppendText(c)
				i = i + 1
			end

		elseif state == "comment" then
			richText:AppendText(c)
			i = i + 1

		elseif state == "string" then
			richText:AppendText(c)
			if c == "\\" then
				if i + 1 <= len then
					i = i + 1
					richText:AppendText(code:sub(i, i))
				end
			elseif c == stringChar then
				state = "default"
			end
			i = i + 1

		else
			if code:sub(i, i + 3) == "--[[" then
				InsertColor(richText, colors.comment)
				richText:AppendText("--[[")
				state = "blockcomment"
				i = i + 4

			elseif code:sub(i, i + 1) == "--" then
				InsertColor(richText, colors.comment)
				richText:AppendText("--")
				state = "comment"
				i = i + 2
			elseif code:sub(i, i + 1) == "//" then
				InsertColor(richText, colors.comment)
				richText:AppendText("//")
				state = "comment"
				i = i + 2

			elseif code:sub(i, i + 1) == "[[" then
				InsertColor(richText, colors.string)
				richText:AppendText("[[")
				state = "blockstring"
				i = i + 2

			elseif c == "\"" or c == "'" then
				InsertColor(richText, colors.string)
				richText:AppendText(c)
				stringChar = c
				state = "string"
				i = i + 1

			elseif code:sub(i, i + 1) == "==" or code:sub(i, i + 1) == "~=" or code:sub(i, i + 1) == "!=" or code:sub(i, i + 1) == ">=" or code:sub(i, i + 1) == "<=" or code:sub(i, i + 1) == ".." or code:sub(i, i + 1) == "&&" or code:sub(i, i + 1) == "||" then
				InsertColor(richText, colors.operator)
				richText:AppendText(code:sub(i, i + 1))
				i = i + 2

			elseif operators[c] then
				InsertColor(richText, colors.operator)
				richText:AppendText(c)
				i = i + 1

			elseif c == "(" or c == ")" or c == "{" or c == "}" or c == "[" or c == "]" or c == "," or c == ";" then
				InsertColor(richText, colors.punctuation)
				richText:AppendText(c)
				i = i + 1

			elseif c:match("%d") or (c == "." and i + 1 <= len and code:sub(i + 1, i + 1):match("%d")) then
				local startI = i
				if c == "0" and i + 1 <= len and code:sub(i + 1, i + 1):lower() == "x" then
					i = i + 2
					while i <= len and code:sub(i, i):match("[%da-fA-F]") do i = i + 1 end
				else
					while i <= len and code:sub(i, i):match("[%d%.]") do i = i + 1 end
					if i <= len and code:sub(i, i):lower() == "e" then
						i = i + 1
						if i <= len and (code:sub(i, i) == "+" or code:sub(i, i) == "-") then i = i + 1 end
						while i <= len and code:sub(i, i):match("%d") do i = i + 1 end
					end
				end
				InsertColor(richText, colors.number)
				richText:AppendText(code:sub(startI, i - 1))

			elseif c:match("[%a_]") then
				local startI = i
				while i <= len and code:sub(i, i):match("[%w_]") do
					i = i + 1
				end
				local word = code:sub(startI, i - 1)

				local afterWord = i
				while afterWord <= len and code:sub(afterWord, afterWord):match("%s") do
					afterWord = afterWord + 1
				end
				local nextChar = afterWord <= len and code:sub(afterWord, afterWord) or ""
				local isCall = nextChar == "("
				local isLibrary = nextChar == "." or nextChar == ":"

				local beforeStart = startI - 1
				while beforeStart >= 1 and code:sub(beforeStart, beforeStart):match("%s") do
					beforeStart = beforeStart - 1
				end
				local isFuncDecl = beforeStart >= 7 and code:sub(beforeStart - 7, beforeStart) == "function"

				if word == "true" or word == "false" then
					InsertColor(richText, colors.boolean)
				elseif word == "nil" then
					InsertColor(richText, colors.nilVal)
				elseif word == "self" then
					InsertColor(richText, colors.selfVar)
				elseif keywords[word] then
					InsertColor(richText, colors.keyword)
				elseif isFuncDecl then
					InsertColor(richText, colors.funcName)
				elseif isLibrary then
					InsertColor(richText, colors.library)
				elseif isCall and word == "Color" then
					local colorMatch = code:sub(afterWord):match("^%((%s*%d+%s*,%s*%d+%s*,%s*%d+%s*,?%s*%d*%s*)%)")
					if colorMatch then
						local nums = {}
						for n in colorMatch:gmatch("%d+") do
							nums[#nums + 1] = tonumber(n)
						end
						if #nums >= 3 then
							local r, g, b, a = nums[1], nums[2], nums[3], nums[4] or 255
							InsertColor(richText, colors.funcCall)
							richText:AppendText(word)
							InsertColor(richText, colors.punctuation)
							richText:AppendText("(")
							if a < 128 then
								richText:InsertColorChange(255, 255, 255, 255)
							else
								richText:InsertColorChange(r, g, b, 255)
							end
							richText:AppendText(colorMatch)
							InsertColor(richText, colors.punctuation)
							richText:AppendText(")")
							i = afterWord + #colorMatch + 2
							goto continued
						end
					end
					InsertColor(richText, colors.funcCall)
				elseif isCall then
					InsertColor(richText, colors.funcCall)
				else
					InsertColor(richText, colors.default)
				end
				richText:AppendText(word)

				::continued::

			elseif c == ":" or c == "." then
				local nextI = i + 1
				if nextI <= len and code:sub(nextI, nextI):match("[%a_]") then
					local startI = nextI
					while nextI <= len and code:sub(nextI, nextI):match("[%w_]") do
						nextI = nextI + 1
					end
					local member = code:sub(startI, nextI - 1)
					local afterMember = nextI
					while afterMember <= len and code:sub(afterMember, afterMember):match("%s") do
						afterMember = afterMember + 1
					end
					local isMemberCall = afterMember <= len and code:sub(afterMember, afterMember) == "("

					InsertColor(richText, colors.punctuation)
					richText:AppendText(c)

					if isMemberCall then
						InsertColor(richText, colors.funcCall)
					else
						InsertColor(richText, colors.default)
					end
					richText:AppendText(member)
					i = nextI
				else
					InsertColor(richText, colors.punctuation)
					richText:AppendText(c)
					i = i + 1
				end

			else
				richText:AppendText(c)
				i = i + 1
			end
		end
	end

	richText:InvalidateLayout()

	local scrollFrames = 10
	local oldThink = richText.Think
	richText.Think = function(self)
		if oldThink then oldThink(self) end
		if scrollFrames > 0 then
			scrollFrames = scrollFrames - 1
			self:GotoTextStart()
		else
			richText.Think = oldThink
		end
	end
end