function Header(el)
    if el.level == 1 then
        el.classes = {
            'govuk-heading-xl'
        }
    elseif el.level == 2 then
        el.classes = {
            'govuk-heading-l'
        }
    elseif el.level == 3 then
        el.classes = {
            'govuk-heading-m'
        }
    elseif el.level == 4 then
        el.classes = {
            'govuk-heading-s'
        }
    elseif el.level == 5 then
        el.classes = {
            'govuk-body'
        }
    elseif el.level == 6 then
        el.classes = {
            'govuk-body'
        }
    end

    return el
end

-- Classes for paragraphs aren't exposed so using the workaround from here:
-- https://stackoverflow.com/questions/72761776/pandoc-lua-how-to-add-class-to-a-para

function Para(para)
    return pandoc.Plain(
        { pandoc.RawInline('html', '<p class="govuk-body">') } ..
        para.content ..
        { pandoc.RawInline('html', '</p>') }
    )
end