# Fun Quotes System for Terminal
{ pkgs, ... }:

{
  home.packages = [
    (pkgs.writeShellScriptBin "random-quote" ''
      # Array of fun developer/tech quotes
      quotes=(
        "\"There are only 10 types of people in the world: those who understand binary and those who don't.\" 🤓"
        "\"It works on my machine.\" - Every developer ever 🤷‍♂️"
        "\"99 little bugs in the code, 99 little bugs. Take one down, patch it around, 117 little bugs in the code.\" 🐛"
        "\"Programming is like sex: one mistake and you have to support it for the rest of your life.\" - Michael Sinz 😅"
        "\"The best thing about a boolean is even if you are wrong, you are only off by a bit.\" 🔢"
        "\"In order to understand recursion, you must first understand recursion.\" ♻️"
        "\"There are two hard things in computer science: cache invalidation, naming things, and off-by-one errors.\" 🤯"
        "\"Why do programmers prefer dark mode? Because light attracts bugs!\" 🌙"
        "\"A SQL query goes into a bar, walks up to two tables and asks: 'Can I join you?'\" 🍺"
        "\"How many programmers does it take to change a light bulb? None, that's a hardware problem.\" 💡"
        "\"I'm not a great programmer; I'm just a good programmer with great habits.\" - Kent Beck ✨"
        "\"Code never lies, comments sometimes do.\" - Ron Jeffries 📝"
        "\"First, solve the problem. Then, write the code.\" - John Johnson 🧠"
        "\"Experience is the name everyone gives to their mistakes.\" - Oscar Wilde 🎭"
        "\"The most important property of a program is whether it accomplishes the intention of its user.\" - C.A.R. Hoare 🎯"
        "\"Simplicity is the ultimate sophistication.\" - Leonardo da Vinci 🎨"
        "\"Any fool can write code that a computer can understand. Good programmers write code that humans can understand.\" - Martin Fowler 👥"
        "\"Programs must be written for people to read, and only incidentally for machines to execute.\" - Harold Abelson 📚"
        "\"The function of good software is to make the complex appear to be simple.\" - Grady Booch 🔧"
        "\"Walking on water and developing software from a specification are easy if both are frozen.\" - Edward V. Berard ❄️"
        "\"Measuring programming progress by lines of code is like measuring aircraft building progress by weight.\" - Bill Gates ✈️"
        "\"Always code as if the guy who ends up maintaining your code will be a violent psychopath who knows where you live.\" - John Woods 😈"
        "\"Debugging is twice as hard as writing the code in the first place.\" - Brian Kernighan 🔍"
        "\"The best error message is the one that never shows up.\" - Thomas Fuchs ✅"
        "\"A computer is like air conditioning - it becomes useless when you open Windows.\" - Linus Torvalds 🪟"
        "\"Software is like entropy: It is difficult to grasp, weighs nothing, and obeys the Second Law of Thermodynamics.\" - Norman Augustine 🌌"
        "\"The trouble with programmers is that you can never tell what a programmer is doing until it's too late.\" - Seymour Cray ⏰"
        "\"I have always wished for my computer to be as easy to use as my telephone; my wish has come true because I can no longer figure out how to use my telephone.\" - Bjarne Stroustrup 📱"
        "\"If debugging is the process of removing software bugs, then programming must be the process of putting them in.\" - Edsger Dijkstra 🪲"
        "\"Real programmers count from 0.\" 0️⃣"
        "\"There's no place like 127.0.0.1\" 🏠"
        "\"To err is human, but to really foul things up you need a computer.\" - Paul R. Ehrlich 💻"
        "\"The computer was born to solve problems that did not exist before.\" - Bill Gates 🤖"
        "\"Software and cathedrals are much the same – first we build them, then we pray.\" - Sam Redwine 🏰"
        "\"The most likely way for the world to be destroyed, most experts agree, is by accident. That's where we come in; we're computer professionals. We cause accidents.\" - Nathaniel Borenstein 💥"
        "\"Perl – The only language that looks the same before and after RSA encryption.\" - Keith Bostic 🔐"
        "\"Java is to JavaScript what car is to Carpet.\" - Chris Heilmann 🚗"
        "\"PHP is a minor evil perpetrated and created by incompetent amateurs, whereas Perl is a great and insidious evil perpetrated by skilled but perverted professionals.\" - Jon Ribbens 😈"
        "\"Python is executable pseudocode. Perl is executable line noise.\" - Bruce Eckel 🐍"
        "\"C makes it easy to shoot yourself in the foot; C++ makes it harder, but when you do it blows your whole leg off.\" - Bjarne Stroustrup 🦵"
        "\"The only way to learn a new programming language is by writing programs in it.\" - Dennis Ritchie 📖"
        "\"Talk is cheap. Show me the code.\" - Linus Torvalds 💬"
        "\"Good code is its own best documentation.\" - Steve McConnell 📄"
        "\"Code is like humor. When you have to explain it, it's bad.\" - Cory House 😂"
        "\"Programming isn't about what you know; it's about what you can figure out.\" - Chris Pine 🧩"
        "\"The best programmers are not marginally better than merely good ones. They are an order-of-magnitude better.\" - Randall E. Stross 🌟"
        "\"Give a man a program, frustrate him for a day. Teach a man to program, frustrate him for a lifetime.\" - Muhammad Waseem 📚"
        "\"It's not a bug – it's an undocumented feature.\" 🐞"
        "\"I don't always test my code, but when I do, I do it in production.\" - The Most Interesting Man in the World 🧪"
        "\"Roses are red, violets are blue, unexpected '}' on line 32.\" 🌹"
        "\"Home is where you can say 'It works on my machine' and actually mean it.\" 🏡"
      )

      # Get random quote
      quote_count=''${#quotes[@]}
      random_index=$((RANDOM % quote_count))
      selected_quote="''${quotes[$random_index]}"

      # Color codes
      CYAN='\033[0;36m'
      YELLOW='\033[1;33m'
      RESET='\033[0m'

      # Display quote with nice formatting
      echo -e "''${CYAN}┌─ 💭 Quote of the Terminal ─────────────────────────────────────────┐''${RESET}"
      echo -e "''${CYAN}│''${RESET}"
      echo -e "''${CYAN}│''${RESET} ''${YELLOW}$selected_quote''${RESET}"
      echo -e "''${CYAN}│''${RESET}"
      echo -e "''${CYAN}└─────────────────────────────────────────────────────────────────────┘''${RESET}"
    '')

    (pkgs.writeShellScriptBin "quote-of-the-day" ''
      # Generate a daily quote based on date (same quote per day)
      quotes=(
        "\"There are only 10 types of people in the world: those who understand binary and those who don't.\" 🤓"
        "\"It works on my machine.\" - Every developer ever 🤷‍♂️"
        "\"99 little bugs in the code, 99 little bugs. Take one down, patch it around, 117 little bugs in the code.\" 🐛"
        "\"Programming is like sex: one mistake and you have to support it for the rest of your life.\" - Michael Sinz 😅"
        "\"The best thing about a boolean is even if you are wrong, you are only off by a bit.\" 🔢"
        "\"In order to understand recursion, you must first understand recursion.\" ♻️"
        "\"There are two hard things in computer science: cache invalidation, naming things, and off-by-one errors.\" 🤯"
        "\"Why do programmers prefer dark mode? Because light attracts bugs!\" 🌙"
        "\"A SQL query goes into a bar, walks up to two tables and asks: 'Can I join you?'\" 🍺"
        "\"How many programmers does it take to change a light bulb? None, that's a hardware problem.\" 💡"
        "\"Always code as if the guy who ends up maintaining your code will be a violent psychopath who knows where you live.\" - John Woods 😈"
        "\"Debugging is twice as hard as writing the code in the first place.\" - Brian Kernighan 🔍"
        "\"The best error message is the one that never shows up.\" - Thomas Fuchs ✅"
        "\"Talk is cheap. Show me the code.\" - Linus Torvalds 💬"
        "\"Code is like humor. When you have to explain it, it's bad.\" - Cory House 😂"
      )

      # Use day of year as seed for consistent daily quote
      day_of_year=$(date +%j)
      quote_count=''${#quotes[@]}
      daily_index=$((day_of_year % quote_count))
      daily_quote="''${quotes[$daily_index]}"

      # Color codes
      CYAN='\033[0;36m'
      YELLOW='\033[1;33m'
      GREEN='\033[0;32m'
      RESET='\033[0m'

      # Display daily quote
      echo -e "''${GREEN}📅 $(date '+%A, %B %d, %Y') - Quote of the Day:''${RESET}"
      echo -e "''${YELLOW}$daily_quote''${RESET}"
    '')
  ];
}
