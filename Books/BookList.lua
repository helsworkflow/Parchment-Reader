-- BookList.lua - Handles loading and managing books

local function LoadBookFromFile(fileName, bookTitle)
    local path = "Interface\\AddOns\\ParchmentReader\\Books\\" .. fileName
    local content = ""
    
    -- Try to load the file (this is a simplified version)
    -- In actual WoW, you'd need to include the file content directly in Lua
    -- since WoW doesn't allow dynamic file loading for security reasons
    
    return content
end

-- Register books here
-- Each book is stored as a table with lines
local function RegisterBook(bookName, bookContent)
    local lines = {}
    for line in bookContent:gmatch("([^\n]*)\n?") do
        table.insert(lines, line)
    end

    -- pageSize comes straight from the SavedVariables table;
    -- Core.lua guarantees it exists before any other file runs.
    local pageSize  = ParchmentReaderDB and ParchmentReaderDB.pageSize or 25
    local totalPages = math.ceil(#lines / pageSize)
    if totalPages < 1 then totalPages = 1 end

    ParchmentReader.books[bookName] = {
        title      = bookName,
        lines      = lines,
        totalPages = totalPages,
        custom     = true,  -- mark as editable
    }
end

-- Example book content (you can add your own books here)
local exampleBook1 = [[
Welcome to ParchmentReader!

This is an example book that demonstrates how the ParchmentReader addon works.

You can add your own books by editing the BookList.lua file and adding new book content.

Each book is stored as a simple text string, and the addon will automatically paginate it for you.

Features:
- Page navigation with Previous/Next buttons
- Minimap icon for quick access
- Settings panel for customization
- Support for multiple books

How to add books:
1. Open BookList.lua
2. Create a new variable with your book content
3. Call RegisterBook with a name and the content
4. The book will appear in the book list

That's it! Enjoy reading in Azeroth!

This is some additional text to demonstrate pagination.
When you have enough lines, they will automatically split into multiple pages.

Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
Ut enim ad minim veniam, quis nostrud exercitation ullamco.

More content here...
And here...
And even more...

Keep adding text to test the pagination system.
Each page will show a fixed number of lines.
You can adjust this in the settings.

Happy reading!
]]

local exampleBook2 = [[
The Story of a Brave Adventurer

Chapter 1: The Beginning

Once upon a time, in the land of Azeroth, there lived a brave adventurer.

This adventurer had traveled far and wide, seeking glory and treasure.

One day, while exploring a dark forest, they discovered an ancient tome.

The tome was filled with mysterious writings and arcane symbols.

As they began to read, strange things started to happen...

Chapter 2: The Discovery

The words on the pages seemed to glow with an otherworldly light.

Each sentence revealed secrets of the past, forgotten by time.

The adventurer realized this was no ordinary book.

It was a grimoire of immense power, capable of changing reality itself.

But with great power comes great responsibility...

Chapter 3: The Choice

The adventurer now faced a difficult decision.

Should they use the grimoire's power for good?

Or would the temptation of unlimited power corrupt them?

The fate of Azeroth hung in the balance...

To be continued...
]]

-- Initialize books when the addon loads
local function InitializeBooks()
    -- Register example books
    RegisterBook("Welcome Guide", exampleBook1)
    RegisterBook("Adventure Story", exampleBook2)
    
    -- Add more books here as needed
    -- RegisterBook("Your Book Title", yourBookContent)
end

-- Called directly at load time.  Core.lua is listed before this file in the
-- TOC, so ParchmentReader and ParchmentReaderDB are already initialised.
InitializeBooks()
