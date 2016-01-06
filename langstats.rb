#!/usr/bin/ruby

h = Hash.new []
File.open('../datadump/Posts.xml') {|f|
    loop {
        post = f.gets
        break if !post
        next unless post =~ /PostTypeId="2"/
        body = (post.match(/Body="(.*?)"/) || [])[1]
        next unless body
        id = (post.match(/Id="(.*?)"/) || [])[1]
        qid = (post.match(/ParentId="(.*?)"/) || [])[1]
        score = (post.match(/Score="(\d*?)"/) || [])[1].to_i
        #date = (post.match(/CreationDate="(.*?)"/) || [])[1]
        #next unless date =~ /^2015/

        body.gsub!(/&#x([^;]+);/) { $1.to_i(16).chr }

        lang = body.scan(/&lt;h.&gt;(.*?)&lt;\/h.&gt;/).first
        if lang
            lang = lang.first
            lang.downcase!                # standardize case
            lang.gsub! /&lt;.*?&gt;/, ''  # strip html
            lang.strip!                   # whitespace cleanup
            lang.squeeze! ' '             # (cont.)
            lang.gsub! /\s*[(\[].*/, ''   # parens and such

            # filter out numbered answers as soon as possible
            # much of the rest of the code checks for numbers
            lang.gsub! /^\d+\.\s+/, ''

            # adjectives
            lang.gsub! /\s*(plain|pure)\s*/, ''

            # these are almost never part of a language name
            lang.gsub! /\s*([,:\u2010-\u2014]|\s+([+-]|w\/|with)\s+).*/, ''

            # common characters that precede a score
            # also filters out version numbers
            lang.gsub! /(?<=\D)(?<!x)(?<!ti)(?<!hq)(\s*[;(\u2010-\u2014-]?\s*\d).*/, ''

            # a few special cases
            lang.sub!(/^(windows|gnu)\s+/, '')
            lang = 'javascript' if %w[javascript\ es es js].include? lang
            lang = 'bash' if lang =~ /bash.*coreutils/
            lang = 'brainfuck' if lang =~ /^brain[f*][u*][c*][k*]$/
            lang = 'sh' if %w[shell\ script shell].include? lang
            lang = 'delphi' if lang == 'delphi xe'
            lang = 'apl' if lang == 'dyalog apl'

            # these probably aren't language names
            if %w[answer bonus code dissection edit example\ answer \
                  explanation language languages notes output program \
                  reference\ implementation results score solution task test \
                  update].include?(lang) ||
                #lang.count(' ') >= 3 ||
                lang == ''
                # NOP
            else
                #puts "#{lang} ||| #{link}"

                h[lang] += [{
                    id: id,
                    qid: qid,
                    score: score
                }]
            end
        end
    }
}

# if all of the occurences of this "language" were on the same question, it's
# probably not a real language (ex. "factoid")
# this also filters out junk that only occurs once
h.keys.each do |k|
    if h[k].map{|x| x[:qid] }.uniq.length == 1
        h.delete k
    end
end

#puts h.sort_by{|x| x.last.length }.reverse[0..100].map{|x| x[0] + "\thttp://codegolf.stackexchange.com/q/" + x[1][0][:id] }
puts h.sort_by{|x| x.last.length }.reverse.map{|x| x[0] + ': ' + x[1].length.to_s }
#puts h.sort_by{|x| x.last.length }.reverse[0..100].map{|x| "#{x[0]}\t#{(x[1].map{|a| a[:score]}.inject(:+) / x[1].length.to_f).round(3)}\t#{a=x[1].map{|a| a[:score]}.sort; a[a.length / 2]}" }
