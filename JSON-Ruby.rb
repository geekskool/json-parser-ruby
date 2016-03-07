def space_parser input
    if input == nil
        return nil
    else
        first = input[/\S+/]
        indx = input.index(first)
        return input[indx..-1]
    end    
end

def null_parser input
    input = space_parser input
    if input[0..3] == 'null'
        return nil, input[4..-1]
    else
        return nil
    end
end

def bool_parser input
    input = space_parser input
    if input[0..3] == 'true'
        return true, input[4..-1]
    elsif input[0..4] == 'false'
        return false, input[5..-1]
    else
        return nil
    end
end

def num_parser input
    input = space_parser input
    if input[0].match(/\d+/)
        indx = (input.index(',') or input.index(']') or input.index('}'))
        num = input[0...indx]
        if num[/\.\d+/]
            return num.to_f, input[indx..-1]
        elsif num[/\d+/]
            return num.to_i, input[indx..-1]
        else
            return nil
        end
    end
end

def string_parser input
    input = space_parser input    
    if input[0] == '"'
        input = input[1..-1]
        indx = input.gsub('\"', '"').index('"')
        return input[0..(indx-1)], input[(indx+1)..-1]
    else
        return nil
    end
end

def array_parser input
    input = space_parser input
    if input[0] == '['
        array = []
        input.slice!(0)
        while input.size > 0 and input[0] != ']'
            input = space_parser input
            input.slice!(0) if input[0] == ','
            if input[0] == '['
                indx = input.index(']')
                array << array_parser(input)
                input = input[(indx+1)..-1]
            
            elsif input[0] == '{'
                indx = input.index('}')
                array << object_parser(input[0..indx])
                input = input[(indx+1)..-1]
            else
                parsed, rem = element_parser input
                break if rem == nil
                array << parsed
                rem.slice!(0)
                input = rem
            end
        end    
        return array
    else
        return nil
    end
end

def object_parser input
    input = space_parser input
    if input[0] == '{'
        hash = {}
        input.slice!(0)
        while input.size > 0 and input != '}'
            input = space_parser input
            input.slice!(0) if input[0] == ','
            key, rem = string_parser input
            input = space_parser rem
            break if rem == nil
            input.slice!(0) if input[0] == ':'
            if space_parser(input)[0] == '['
                indx = input.index(']')
                value = array_parser(input[0..indx])
                input = input[(indx+1)..-1]
            elsif space_parser(input)[0] == '{'
                indx = input.index('}')
                value = object_parser(input[0..indx])
                input = input[(indx+1)..-1]
            else
                value, rem = element_parser input
                input = rem
            end
            break if rem == nil
            hash[key] = value
        end
        return hash
    else
        return nil
    end
end

def element_parser input
    return array_parser(input) if array_parser(input)
    return null_parser(input) if null_parser(input)
    return bool_parser(input) if bool_parser(input)
    return num_parser(input) if num_parser(input)
    return string_parser(input) if string_parser(input)
end


input = '{
    "glossary": {
        "title": "example glossary",
        "GlossDiv": {
            "title": "S",
            "GlossList": {
                "GlossEntry": {
                    "ID": "SGML",
                    "SortAs": "SGML",
                    "GlossTerm": "Standard Generalized Markup Language",
                    "Acronym": "SGML",
                    "Abbrev": "ISO 8879:1986",
                    "GlossDef": {
                        "para": "A meta-markup language, used to create markup languages such as DocBook.",
                        "GlossSeeAlso": ["GML", "XML"]
                    },
                    "GlossSee": "markup"
                }
            }
        }
    }
}' 
input = input.strip
p array_parser(input) if input[0] == '['
p object_parser(input) if input[0] == '{'
