IRB.conf[:PROMPT][:CLOUD_PROMPT] = {
  :PROMPT_I => "\e[31mirb #{ENV['RACK_ENV']}: \e[0m",
}

IRB.conf[:PROMPT][:DEV_PROMPT] = {
  :PROMPT_I => "irb #{ENV['RACK_ENV']}: ",
}

if ENV['RACK_ENV'][/dev/]
  IRB.conf[:PROMPT_MODE] = :DEV_PROMPT
else
  IRB.conf[:SAVE_HISTORY] = 100
  IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb-history"
  IRB.conf[:PROMPT_MODE] = :CLOUD_PROMPT
end
