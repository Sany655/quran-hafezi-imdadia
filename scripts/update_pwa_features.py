import os
import re

# Read original docs/reader.html
with open('docs/reader.html', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. HTML Replacement
wudu_and_planner_html = '''  <!-- Wudu & Purity Adab Gateway Modal -->
  <div id="wuduGatewayModal" class="fixed inset-0 z-[100] flex items-center justify-center bg-slate-950/90 backdrop-blur-md p-4 font-bengali overflow-y-auto transition-opacity duration-300">
    <div class="max-w-md w-full bg-gradient-to-b from-[#061e12] via-[#0b3821] to-[#04160d] text-white rounded-3xl p-5 sm:p-6 shadow-2xl border border-gold-500/40 space-y-4 my-auto relative">
      <!-- Icon & Bismillah -->
      <div class="text-center space-y-2">
        <div class="w-14 h-14 mx-auto rounded-full bg-emerald-800 border-2 border-gold-500/80 flex items-center justify-center shadow-lg shadow-gold-500/20 text-gold-300 text-2xl">
          📖
        </div>
        <div class="text-xl sm:text-2xl font-serif text-gold-300 font-bold tracking-wide">
          بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ
        </div>
        <div class="text-sm font-bold text-white tracking-wide">
          পবিত্রতা ও তিলাওয়াতের আদব
        </div>
      </div>

      <!-- Ayah Card -->
      <div class="p-4 rounded-2xl bg-white/5 border border-gold-500/30 text-center space-y-2">
        <div class="text-base sm:text-lg font-serif text-amber-100 font-semibold leading-relaxed">
          إِنَّهُ لَقُرْآنٌ كَرِيمٌ ﴿٧٧﴾ فِي كِتَابٍ مَّكْنُونٍ ﴿٧٨﴾ لَّا يَمَسُّهُ إِلَّا الْمُطَهَّরُونَ ﴿٧٩﴾
        </div>
        <div class="w-16 h-px bg-gold-500/40 mx-auto my-1.5"></div>
        <p class="text-xs sm:text-sm text-slate-200 italic leading-relaxed">
          “নিশ্চয় এটি এক সম্মানিত কুরআন, যা আছে সুরক্ষিত কিতাবে; পবিত্রগণ ব্যতীত অন্য কেউ তা স্পর্শ করে না।”
        </p>
        <span class="text-[11px] font-bold text-gold-300 block">
          (সূরা আল-ওয়াকি'আহ: ৭৭-৭৯)
        </span>
      </div>

      <!-- Mobile Touch Guidance Card -->
      <div class="p-3.5 rounded-2xl bg-emerald-950/70 border border-emerald-700/50 space-y-2 text-xs leading-relaxed text-slate-200">
        <div class="flex items-center gap-2 font-bold text-gold-300 text-xs">
          <span>📱</span>
          <span>মোবাইলে কুরআন স্পর্শের বিধান</span>
        </div>
        <p class="text-[11.5px] text-slate-200 leading-normal">
          অনেকে মনে করেন মোবাইলের স্ক্রিনে কোরআন থাকলে অজুর প্রয়োজন নেই। কিন্তু ফুকাহায়ে কিরাম ও ওলামাদের নির্ভরযোগ্য ও সতর্কতামূলক ফতোয়া অনুযায়ী: মোবাইলের পর্দায় যখন কুরআনের আয়াত দৃশ্যমান থাকে, তখন বিনা অজুতে সরাসরি স্ক্রিনের আয়াতের ওপর হাত বা আঙুল লাগানো থেকে বিরত থাকা উচিত।
        </p>
        <div class="p-2 rounded-xl bg-black/30 border border-sky-500/20 text-sky-200 text-[11px] flex items-start gap-2">
          <span class="text-sky-400">💧</span>
          <span>কুরআনের পূর্ণ বরকত ও সর্বোচ্চ সম্মান প্রদর্শনের জন্য তিলাওয়াত শুরুর পূর্বে অজু করে নেওয়া সবচেয়ে উত্তম ও নিরাপদ।</span>
        </div>
      </div>

      <!-- Quick Adab Pills -->
      <div class="grid grid-cols-3 gap-2 text-center text-[10.5px]">
        <div class="p-2 rounded-xl bg-white/5 border border-white/10 text-slate-200 flex flex-col items-center gap-1">
          <span class="text-gold-300 text-sm">✓</span>
          <span>অজু নিশ্চিত করুন</span>
        </div>
        <div class="p-2 rounded-xl bg-white/5 border border-white/10 text-slate-200 flex flex-col items-center gap-1">
          <span class="text-gold-300 text-sm">🎙️</span>
          <span>ধীরে ধীরে তিলাওয়াত</span>
        </div>
        <div class="p-2 rounded-xl bg-white/5 border border-white/10 text-slate-200 flex flex-col items-center gap-1">
          <span class="text-gold-300 text-sm">❤️</span>
          <span>একনিষ্ঠ মনযোগ</span>
        </div>
      </div>

      <!-- Slide to Enter Action -->
      <div class="pt-2 text-center space-y-2">
        <div class="text-[11.5px] text-slate-300 font-medium">
          অজু অবস্থায় পবিত্র অন্তরে তিলাওয়াত শুরু করুন
        </div>
        <!-- Slider Container -->
        <div id="wuduSliderTrack" class="relative w-full h-14 rounded-full bg-emerald-950/80 border-2 border-gold-500/60 p-1 flex items-center overflow-hidden cursor-pointer select-none">
          <div id="wuduSliderFill" class="absolute left-0 top-0 bottom-0 bg-emerald-700/60 rounded-full transition-all duration-75" style="width: 48px;"></div>
          <div id="wuduSliderText" class="w-full text-center text-gold-300 font-bold text-xs sm:text-sm tracking-wide z-10 pointer-events-none transition-opacity duration-150">
            স্লাইড করে প্রবেশ করুন »»
          </div>
          <div id="wuduSliderThumb" class="absolute left-1 top-1 w-12 h-12 rounded-full bg-gradient-to-r from-gold-300 to-gold-500 text-emerald-950 flex items-center justify-center font-bold text-lg shadow-lg z-20 cursor-grab active:cursor-grabbing transition-transform duration-75">
            ➔
          </div>
        </div>
        <button id="skipWuduGatewayBtn" class="text-[11px] text-gold-400 hover:text-gold-300 underline pt-1">
          সরাসরি তিলাওয়াতে প্রবেশ করুন →
        </button>
      </div>
    </div>
  </div>

  <!-- 4. Huffaz Routine & Tri-Calendar Modal (Draft v3 Architecture) -->
  <div id="plannerModalBackdrop" class="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 hidden opacity-0 transition-opacity duration-300 flex items-end sm:items-center justify-center p-0 sm:p-4 font-bengali">
    <div id="plannerModalContent" class="w-full max-w-2xl bg-white dark:bg-slate-900 rounded-t-3xl sm:rounded-3xl shadow-2xl flex flex-col max-h-[90dvh] sm:max-h-[85vh] overflow-hidden transform translate-y-full transition-transform duration-300 pb-[env(safe-area-inset-bottom,0px)] relative">
      
      <!-- Header -->
      <div class="p-3.5 sm:p-4 bg-emerald-900 text-white flex items-center justify-between border-b border-emerald-800 shrink-0">
        <div>
          <div class="flex items-center gap-2">
            <h2 id="plannerModalMainTitle" class="font-bold text-base sm:text-lg text-white">কুরআন তিলাওয়াত ট্র্যাকার</h2>
            <span class="text-[10px] bg-gold-500 text-emerald-950 font-bold px-2 py-0.5 rounded-full">v3 অফলাইন</span>
          </div>
          <p id="plannerTodayTriDate" class="text-xs text-gold-300 font-medium mt-0.5"></p>
        </div>
        <div class="flex items-center gap-1">
          <button id="openPlannerSettingsBtn" class="p-2 rounded-xl hover:bg-emerald-800 text-gold-300 hover:text-white transition" title="প্ল্যানার সেটিংস">
            ⚙️
          </button>
          <button id="closePlannerBtn" class="p-2 rounded-xl hover:bg-emerald-800 text-emerald-200 transition" title="বন্ধ করুন">
            ✕
          </button>
        </div>
      </div>

      <!-- Navigation Tabs (3 Clean Tabs, no persistent mode bar) -->
      <div class="px-3 py-1.5 bg-slate-100 dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700 flex items-center gap-1.5 shrink-0">
        <button id="plannerTabToday" class="flex-1 py-2 px-2 rounded-xl text-xs font-bold bg-white dark:bg-slate-700 text-emerald-800 dark:text-emerald-300 shadow-sm transition text-center">
          🌿 আজকের ফোকাস
        </button>
        <button id="plannerTabRoadmap" class="flex-1 py-2 px-2 rounded-xl text-xs font-semibold text-slate-600 dark:text-slate-400 hover:text-emerald-700 transition text-center">
          🎯 রোডম্যাপ ও প্ল্যান
        </button>
        <button id="plannerTabDiary" class="flex-1 py-2 px-2 rounded-xl text-xs font-semibold text-slate-600 dark:text-slate-400 hover:text-emerald-700 transition text-center">
          📝 কুরআনিক ডায়েরি
        </button>
      </div>

      <!-- Scrollable Tab Content Container -->
      <div class="flex-1 overflow-y-auto p-3 sm:p-4 space-y-4 no-scrollbar">

        <!-- TAB 1: Today's Focus -->
        <div id="plannerViewToday" class="space-y-4">
          <!-- 1. Horizontal Date Strip (11 days) -->
          <div>
            <div class="text-[11px] font-bold text-slate-500 dark:text-slate-400 mb-1.5 px-0.5 flex items-center justify-between">
              <span>দিন নির্বাচন করুন:</span>
              <span id="dateStripCurrentLabel" class="text-emerald-700 dark:text-emerald-400 font-semibold"></span>
            </div>
            <div id="plannerDateStrip" class="flex items-center gap-2 overflow-x-auto pb-1 no-scrollbar">
              <!-- Dynamically populated via JS -->
            </div>
          </div>

          <!-- 2. Today's Action Card -->
          <div id="selectedDayCard" class="p-4 rounded-2xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 shadow-sm space-y-3">
            <div class="flex items-center justify-between pb-2 border-b border-slate-200 dark:border-slate-700">
              <div>
                <span class="text-[11px] font-bold text-gold-600 dark:text-gold-400">নির্বাচিত দিনের লক্ষ্য</span>
                <h3 id="selectedDateHeader" class="text-sm sm:text-base font-bold text-slate-900 dark:text-white"></h3>
              </div>
              <button id="toggleDayStatusBtn" class="px-3 py-1.5 rounded-xl text-xs font-bold transition flex items-center gap-1.5">
                <!-- Status icon + text populated via JS -->
              </button>
            </div>

            <!-- General Mode Input -->
            <div id="sectionGeneralMode" class="space-y-2.5">
              <label class="text-xs font-bold text-slate-700 dark:text-slate-300 block">আজকের তিলাওয়াত (পৃষ্ঠা/পারা):</label>
              <div class="flex items-center gap-2">
                <input type="text" id="generalTilawatInput" placeholder="যেমন: পারা ১ অথবা পৃষ্ঠা ১-২০" class="flex-1 px-3 py-2 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-xs sm:text-sm font-bengali">
                <button id="saveGeneralTilawatBtn" class="px-4 py-2 bg-emerald-700 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition shrink-0 shadow-sm">
                  সংরক্ষণ
                </button>
              </div>
            </div>

            <!-- Hafiz Mode Input -->
            <div id="sectionHafizMode" class="hidden space-y-2.5">
              <label class="text-xs font-bold text-slate-700 dark:text-slate-300 block">আজকের রিভিশন পারা (দাওর):</label>
              <div class="flex items-center gap-2">
                <input type="text" id="hafizDourInput" placeholder="যেমন: ৩য় ও ৪র্থ পারা" class="flex-1 px-3 py-2 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-xs sm:text-sm font-bengali">
                <button id="saveHafizDourBtn" class="px-4 py-2 bg-emerald-700 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition shrink-0 shadow-sm">
                  সংরক্ষণ
                </button>
              </div>
            </div>

            <!-- Student Mode Input -->
            <div id="sectionStudentMode" class="hidden space-y-2.5">
              <div class="grid grid-cols-1 sm:grid-cols-3 gap-2">
                <div>
                  <span class="text-[11px] font-bold text-emerald-700 dark:text-emerald-400">১. সবক (নতুন):</span>
                  <input type="text" id="studentSabakInput" placeholder="পেজ/আয়াত..." class="w-full mt-1 px-2.5 py-1.5 text-xs rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900">
                </div>
                <div>
                  <span class="text-[11px] font-bold text-teal-700 dark:text-teal-400">২. সবকী (সাম্প্রতিক):</span>
                  <input type="text" id="studentSabkiInput" placeholder="পেজ ৭-১২..." class="w-full mt-1 px-2.5 py-1.5 text-xs rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900">
                </div>
                <div>
                  <span class="text-[11px] font-bold text-cyan-700 dark:text-cyan-400">৩. দাওর (পুরনো):</span>
                  <input type="text" id="studentDourInput" placeholder="পারা ৫..." class="w-full mt-1 px-2.5 py-1.5 text-xs rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900">
                </div>
              </div>
              <button id="saveStudentRoutineBtn" class="w-full py-2 bg-emerald-700 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition shadow-sm">
                শিক্ষার্থী রুটিন সংরক্ষণ
              </button>
            </div>
          </div>

          <!-- 3. Khatam Progress Card -->
          <div class="p-4 rounded-2xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 shadow-sm space-y-2.5">
            <div class="flex items-center justify-between">
              <span class="text-xs font-bold text-slate-800 dark:text-slate-200">চলতি খতমের অগ্রগতি</span>
              <span id="khatamPercentBadge" class="text-xs bg-emerald-100 dark:bg-emerald-950 text-emerald-800 dark:text-emerald-300 font-bold px-2.5 py-0.5 rounded-full">০% সম্পন্ন</span>
            </div>
            <div class="w-full bg-slate-100 dark:bg-slate-700 rounded-full h-2.5 overflow-hidden">
              <div id="khatamProgressBar" class="bg-emerald-600 h-2.5 rounded-full transition-all duration-300" style="width: 0%"></div>
            </div>
            <div class="flex items-center justify-between text-[11px] text-slate-500 dark:text-slate-400 pt-0.5">
              <span id="khatamCompletedDaysText">মোট পড়া হয়েছে: ০ দিন</span>
              <span id="khatamTargetDaysText">টার্গেট: ৩০ দিন</span>
            </div>
          </div>

          <!-- 4. 7-Day Consistency Streak -->
          <div class="p-4 rounded-2xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 shadow-sm space-y-2.5">
            <div class="flex items-center justify-between">
              <span class="text-xs font-bold text-slate-800 dark:text-slate-200">গত ৭ দিনের ধারাবাহিকতা (Streak)</span>
              <span id="streakCountBadge" class="text-xs font-bold text-emerald-700 dark:text-emerald-400">০/৭ দিন</span>
            </div>
            <div id="sevenDayStreakContainer" class="flex items-center justify-around pt-1">
              <!-- Dynamically populated via JS -->
            </div>
          </div>
        </div>

        <!-- TAB 2: Roadmap & Plan -->
        <div id="plannerViewRoadmap" class="hidden space-y-4">
          <div class="p-4 rounded-2xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 space-y-3">
            <h3 class="text-sm font-bold text-slate-900 dark:text-white flex items-center gap-2">
              <span id="cycleViewIcon">🎯</span>
              <span id="cycleViewTitle">খতম ও দাওর রোডম্যাপ নির্ধারণ</span>
            </h3>
            <p id="cycleViewDesc" class="text-xs text-slate-600 dark:text-slate-400 leading-relaxed">
              আপনার সুবিধাজনক সময় নির্বাচন করলে অ্যাপ স্বয়ংক্রিয়ভাবে প্রতিদিনের পড়ার টার্গেট রোডম্যাপ সাজিয়ে দেবে।
            </p>

            <div class="space-y-3 pt-1">
              <div>
                <label id="cycleTargetDaysLabel" class="text-xs font-bold text-slate-700 dark:text-slate-300">টার্গেট সময়সীমা:</label>
                <select id="cycleTargetDaysSelect" class="w-full mt-1 px-3 py-2 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-xs font-bengali">
                  <option value="30" selected>৩০ দিনে খতম (প্রতিদিন ১ পারা / ২০ পৃষ্ঠা)</option>
                  <option value="60">৬০ দিনে খতম (প্রতিদিন আধা পারা / ১০ পৃষ্ঠা)</option>
                  <option value="90">৯০ দিনে খতম (প্রতিদিন ৭ পৃষ্ঠা)</option>
                  <option value="120">১২০ দিনে খতম (প্রতিদিন ৫ পৃষ্ঠা)</option>
                  <option value="365">১ বছরে খতম (প্রতিদিন ১-২ পৃষ্ঠা)</option>
                </select>
              </div>

              <div class="grid grid-cols-2 gap-3">
                <div>
                  <label class="text-xs font-bold text-slate-700 dark:text-slate-300">শুরুর পারা (১-৩০):</label>
                  <input type="number" id="cycleStartParaInput" min="1" max="30" value="1" 
                         class="w-full mt-1 px-3 py-2 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-xs font-mono font-bold">
                </div>
                <div>
                  <label class="text-xs font-bold text-slate-700 dark:text-slate-300">শুরুর তারিখ:</label>
                  <input type="date" id="cycleStartDateInput" class="w-full mt-1 px-3 py-2 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-xs font-mono">
                </div>
              </div>

              <button id="generateCycleBtn" class="w-full py-2.5 bg-emerald-700 hover:bg-emerald-600 text-white rounded-xl text-xs sm:text-sm font-semibold transition shadow-md">
                রোডম্যাপ তৈরি সম্পন্ন করুন
              </button>
            </div>
          </div>

          <div id="cycleSummaryBox" class="hidden p-4 rounded-2xl bg-emerald-900 text-white space-y-1.5 shadow-md">
            <div id="cycleSummaryTitle" class="text-xs font-bold text-gold-300">✓ রোডম্যাপ সফলভাবে প্রস্তুত হয়েছে!</div>
            <p id="cycleSummaryText" class="text-xs text-emerald-100 leading-relaxed"></p>
          </div>

          <!-- Tilawat Tips Card -->
          <div class="p-4 rounded-2xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 space-y-2 text-xs text-slate-600 dark:text-slate-400 leading-relaxed">
            <div class="font-bold text-emerald-800 dark:text-emerald-300">💡 নিয়মিত তিলাওয়াতের পরামর্শ:</div>
            <p>১. প্রতিদিন নির্দিষ্ট সময়ে (যেমন: ফজরের পর) তিলাওয়াত সম্পন্ন করার চেষ্টা করুন।</p>
            <p>২. এক বসায় সম্ভব না হলে ৫ ওয়াক্ত নামাজের পর ৪ পৃষ্ঠা করে পড়লে দিনে ১ পারা শেষ হয়।</p>
            <p>৩. হাফেজ ভাইদের জন্য প্রতিদিনের সবক ও সবকি তাজা রাখা দাওরের পূর্বশর্ত।</p>
          </div>
        </div>

        <!-- TAB 3: Quranic Diary & Notes -->
        <div id="plannerViewDiary" class="hidden space-y-4">
          <!-- Add Note Card -->
          <div class="p-4 rounded-2xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 space-y-3 shadow-sm">
            <div class="text-xs font-bold text-slate-800 dark:text-slate-200">
              ভুল বা তিলাওয়াত নোট টুকে রাখুন:
            </div>
            <div class="flex items-center gap-2">
              <input type="number" id="notePageInput" placeholder="পৃষ্ঠা (১-৬১২)" min="1" max="612" 
                     class="w-28 px-3 py-2 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-xs font-mono font-bold text-center">
              <input type="text" id="noteTextInput" placeholder="ভুল শব্দ বা বিশেষ আয়াত..." 
                     class="flex-1 px-3 py-2 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-xs font-bengali">
              <button id="addSelfCorrectionBtn" class="px-4 py-2 bg-emerald-700 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition shrink-0 shadow-sm">
                + সংরক্ষণ
              </button>
            </div>
          </div>

          <!-- Notes List -->
          <div class="space-y-2">
            <div class="flex items-center justify-between pb-1">
              <h3 id="notesListMainTitle" class="text-xs font-bold text-slate-800 dark:text-slate-200">সংরক্ষিত নোটসমূহ</h3>
              <span id="totalNotesCountBadge" class="text-xs bg-emerald-100 dark:bg-emerald-950 text-emerald-800 dark:text-emerald-300 font-bold px-2 py-0.5 rounded-full"></span>
            </div>
            <div id="allNotesListContainer" class="space-y-2 max-h-[50vh] overflow-y-auto no-scrollbar">
              <!-- Dynamically populated via JS -->
            </div>
          </div>
        </div>

      </div>

      <!-- Settings Overlay / Drawer inside Planner -->
      <div id="plannerSettingsModal" class="hidden absolute inset-0 bg-white dark:bg-slate-900 z-30 p-4 sm:p-5 flex flex-col justify-between overflow-y-auto font-bengali">
        <div class="space-y-4">
          <div class="flex items-center justify-between pb-2 border-b border-slate-200 dark:border-slate-700">
            <div class="flex items-center gap-2">
              <span class="text-lg">⚙️</span>
              <h3 class="font-bold text-base text-slate-900 dark:text-white">প্ল্যানার সেটিংস ও প্রোফাইল</h3>
            </div>
            <button id="closePlannerSettingsBtn" class="p-1.5 rounded-lg text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800 transition">✕</button>
          </div>

          <!-- Profile Mode -->
          <div class="space-y-2">
            <label class="text-xs font-bold text-slate-800 dark:text-slate-200">আপনার প্রোফাইল মোড:</label>
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-2">
              <button data-mode="general" class="planner-mode-btn p-3 rounded-2xl border text-left transition flex flex-col gap-1">
                <span class="font-bold text-xs">🌿 সাধারণ তিলাওয়াত</span>
                <span class="text-[11px] text-slate-500">দৈনিক তিলাওয়াত ও খতম</span>
              </button>
              <button data-mode="student" class="planner-mode-btn p-3 rounded-2xl border text-left transition flex flex-col gap-1">
                <span class="font-bold text-xs">📖 শিক্ষার্থী</span>
                <span class="text-[11px] text-slate-500">সবক, সবকি ও আমপারা</span>
              </button>
              <button data-mode="hafiz" class="planner-mode-btn p-3 rounded-2xl border text-left transition flex flex-col gap-1">
                <span class="font-bold text-xs">🌟 হুফ্ফাজ মোড</span>
                <span class="text-[11px] text-slate-500">মঞ্জিল ও দাওর সাইকেল</span>
              </button>
            </div>
          </div>

          <!-- Daily Reminder Setting -->
          <div class="p-3.5 rounded-2xl bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 space-y-2">
            <div class="flex items-center justify-between">
              <div>
                <div class="text-xs font-bold text-slate-800 dark:text-slate-200">দৈনিক তিলাওয়াত রিমাইন্ডার:</div>
                <div class="text-[11px] text-slate-500">প্রতিদিন নির্দিষ্ট সময়ে তিলাওয়াতের তাগিদ</div>
              </div>
              <input type="checkbox" id="plannerReminderToggle" class="w-5 h-5 accent-emerald-600 rounded cursor-pointer">
            </div>
            <div id="plannerReminderTimeContainer" class="flex items-center gap-2 pt-1">
              <span class="text-xs text-slate-600 dark:text-slate-400">সময়:</span>
              <input type="time" id="plannerReminderTimeInput" value="06:00" class="px-3 py-1.5 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-xs font-mono font-bold">
            </div>
          </div>

          <!-- Hijri Offset -->
          <div class="p-3.5 rounded-2xl bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 space-y-2">
            <div class="flex items-center justify-between">
              <span class="text-xs font-bold text-slate-800 dark:text-slate-200">হিজরি তারিখ সমন্বয়:</span>
              <span id="hijriOffsetLabel" class="text-xs font-bold text-emerald-700 dark:text-emerald-400 font-mono">০ দিন</span>
            </div>
            <div class="flex items-center gap-1.5 pt-1">
              <button data-offset="-2" class="offset-btn flex-1 py-1.5 rounded-xl border text-xs font-semibold">-২</button>
              <button data-offset="-1" class="offset-btn flex-1 py-1.5 rounded-xl border text-xs font-semibold">-১</button>
              <button data-offset="0" class="offset-btn flex-1 py-1.5 rounded-xl border text-xs font-semibold bg-emerald-600 text-white">০</button>
              <button data-offset="1" class="offset-btn flex-1 py-1.5 rounded-xl border text-xs font-semibold">+১</button>
              <button data-offset="2" class="offset-btn flex-1 py-1.5 rounded-xl border text-xs font-semibold">+২</button>
            </div>
          </div>

          <!-- Offline Backup & Reset -->
          <div class="flex items-center gap-2 pt-1">
            <button id="backupDownloadBtn" class="flex-1 py-2.5 rounded-xl bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 text-slate-700 dark:text-slate-300 text-xs font-semibold transition border border-slate-300 dark:border-slate-700">
              📥 ব্যাকআপ ডাউনলোড
            </button>
            <label class="flex-1 py-2.5 rounded-xl bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 text-slate-700 dark:text-slate-300 text-xs font-semibold transition text-center cursor-pointer border border-slate-300 dark:border-slate-700">
              📤 রিস্টোর
              <input type="file" id="restoreFileInput" accept=".json" class="hidden">
            </label>
            <button id="resetPlannerProgressBtn" class="px-3 py-2.5 rounded-xl text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/40 border border-rose-300 text-xs font-semibold transition">
              রিসেট
            </button>
          </div>
        </div>

        <div class="pt-4 border-t border-slate-200 dark:border-slate-700">
          <button id="savePlannerSettingsBtn" class="w-full py-2.5 bg-emerald-700 hover:bg-emerald-600 text-white rounded-xl text-xs sm:text-sm font-bold transition shadow-md">
            সেটিংস সংরক্ষণ করুন
          </button>
        </div>
      </div>

    </div>
  </div>
'''

# 2. JS Replacement
planner_js = '''    // ==========================================
    // PLANNER STATE & DATA MANAGEMENT (Draft v3)
    // ==========================================
    const PLANNER_STORAGE_KEY = 'quran_huffaz_planner_v3';
    let plannerState = {
      profileMode: 'general', // 'general' | 'student' | 'hafiz'
      hijriOffset: 0,
      activeTab: 'today', // 'today' | 'roadmap' | 'diary'
      targetDays: 30,
      reminderEnabled: false,
      reminderTime: '06:00',
      logs: {} // dateKey -> { dourPara, status, sabak, sabki, studentDour, generalTilawat, notes: [] }
    };

    function loadPlannerData() {
      try {
        const raw = localStorage.getItem(PLANNER_STORAGE_KEY);
        if (raw) {
          const parsed = JSON.parse(raw);
          plannerState = { ...plannerState, ...parsed };
        }
      } catch (e) {
        console.error('Failed to load planner data', e);
      }
    }

    function savePlannerData() {
      try {
        localStorage.setItem(PLANNER_STORAGE_KEY, JSON.stringify(plannerState));
      } catch (e) {
        console.error('Failed to save planner data', e);
      }
    }

    let selectedPlannerDate = new Date();

    const openPlannerBtn = document.getElementById('openPlannerBtn');
    const closePlannerBtn = document.getElementById('closePlannerBtn');
    const plannerModalBackdrop = document.getElementById('plannerModalBackdrop');
    const plannerModalContent = document.getElementById('plannerModalContent');

    function openPlannerSheet() {
      loadPlannerData();
      renderTodayTriDate();
      updatePlannerModeUI();
      switchPlannerTab(plannerState.activeTab || 'today');
      plannerModalBackdrop.classList.remove('hidden');
      setTimeout(() => {
        plannerModalBackdrop.classList.remove('opacity-0');
        plannerModalContent.classList.remove('translate-y-full');
      }, 10);
    }

    function closePlannerSheet() {
      plannerModalBackdrop.classList.add('opacity-0');
      plannerModalContent.classList.add('translate-y-full');
      setTimeout(() => {
        plannerModalBackdrop.classList.add('hidden');
      }, 300);
    }

    if (openPlannerBtn) openPlannerBtn.addEventListener('click', openPlannerSheet);
    if (closePlannerBtn) closePlannerBtn.addEventListener('click', closePlannerSheet);
    if (plannerModalBackdrop) {
      plannerModalBackdrop.addEventListener('click', (e) => {
        if (e.target === plannerModalBackdrop) closePlannerSheet();
      });
    }

    function renderTodayTriDate() {
      const banner = document.getElementById('plannerTodayTriDate');
      if (banner) {
        banner.textContent = 'আজ: ' + formatTriDateFull(new Date(), plannerState.hijriOffset);
      }
    }

    function updatePlannerModeUI() {
      const mode = plannerState.profileMode || 'general';
      const mainTitle = document.getElementById('plannerModalMainTitle');
      if (mainTitle) {
        if (mode === 'general') {
          mainTitle.textContent = 'কুরআন তিলাওয়াত ট্র্যাকার';
        } else if (mode === 'student') {
          mainTitle.textContent = 'হিফজ শিক্ষার্থী রুটিন';
        } else {
          mainTitle.textContent = 'হুফ্ফাজ দাওর ট্র্যাকার';
        }
      }

      // Sections in Today View
      const secGen = document.getElementById('sectionGeneralMode');
      const secHaf = document.getElementById('sectionHafizMode');
      const secStu = document.getElementById('sectionStudentMode');

      if (secGen) secGen.classList.toggle('hidden', mode !== 'general');
      if (secHaf) secHaf.classList.toggle('hidden', mode !== 'hafiz');
      if (secStu) secStu.classList.toggle('hidden', mode !== 'student');

      // Update cycle options in roadmap view
      const cycleSelect = document.getElementById('cycleTargetDaysSelect');
      if (cycleSelect) {
        if (mode === 'general') {
          cycleSelect.innerHTML = `
            <option value="30" selected>৩০ দিনে খতম (প্রতিদিন ১ পারা / ২০ পৃষ্ঠা)</option>
            <option value="60">৬০ দিনে খতম (প্রতিদিন আধা পারা / ১০ পৃষ্ঠা)</option>
            <option value="90">৯০ দিনে খতম (প্রতিদিন ৭ পৃষ্ঠা)</option>
            <option value="120">১২০ দিনে খতম (প্রতিদিন ৫ পৃষ্ঠা)</option>
            <option value="365">১ বছরে খতম (প্রতিদিন ১-২ পৃষ্ঠা)</option>
          `;
        } else if (mode === 'student') {
          cycleSelect.innerHTML = `
            <option value="15">১৫ দিনে রিভিশন (প্রতিদিন ২ পারা)</option>
            <option value="20">২০ দিনে রিভিশন (প্রতিদিন ১.৫ পারা)</option>
            <option value="30" selected>৩০ দিনে রিভিশন (প্রতিদিন ১ পারা)</option>
            <option value="60">৬০ দিনে রিভিশন (প্রতিদিন আধা পারা)</option>
          `;
        } else {
          cycleSelect.innerHTML = `
            <option value="7">৭ দিনে খতম (প্রতিদিন ৪-৫ পারা)</option>
            <option value="10">১০ দিনে খতম (প্রতিদিন ৩ পারা)</option>
            <option value="15">১৫ দিনে খতম (প্রতিদিন ২ পারা)</option>
            <option value="20">২০ দিনে খতম (প্রতিদিন ১.৫ পারা)</option>
            <option value="30" selected>৩০ দিনে খতম (প্রতিদিন ১ পারা)</option>
          `;
        }
      }
    }

    // Tab Switching
    const plannerTabToday = document.getElementById('plannerTabToday');
    const plannerTabRoadmap = document.getElementById('plannerTabRoadmap');
    const plannerTabDiary = document.getElementById('plannerTabDiary');

    const plannerViewToday = document.getElementById('plannerViewToday');
    const plannerViewRoadmap = document.getElementById('plannerViewRoadmap');
    const plannerViewDiary = document.getElementById('plannerViewDiary');

    function switchPlannerTab(tabName) {
      plannerState.activeTab = tabName;
      savePlannerData();

      const tabs = [
        { id: 'today', btn: plannerTabToday, view: plannerViewToday },
        { id: 'roadmap', btn: plannerTabRoadmap, view: plannerViewRoadmap },
        { id: 'diary', btn: plannerTabDiary, view: plannerViewDiary }
      ];

      tabs.forEach(t => {
        if (t.id === tabName) {
          if (t.btn) {
            t.btn.className = 'flex-1 py-2 px-2 rounded-xl text-xs font-bold bg-white dark:bg-slate-700 text-emerald-800 dark:text-emerald-300 shadow-sm transition text-center';
          }
          if (t.view) t.view.classList.remove('hidden');
        } else {
          if (t.btn) {
            t.btn.className = 'flex-1 py-2 px-2 rounded-xl text-xs font-semibold text-slate-600 dark:text-slate-400 hover:text-emerald-700 transition text-center';
          }
          if (t.view) t.view.classList.add('hidden');
        }
      });

      if (tabName === 'today') renderPlannerTodayView();
      if (tabName === 'roadmap') renderPlannerRoadmapView();
      if (tabName === 'diary') renderPlannerDiaryView();
    }

    if (plannerTabToday) plannerTabToday.addEventListener('click', () => switchPlannerTab('today'));
    if (plannerTabRoadmap) plannerTabRoadmap.addEventListener('click', () => switchPlannerTab('roadmap'));
    if (plannerTabDiary) plannerTabDiary.addEventListener('click', () => switchPlannerTab('diary'));

    // TAB 1: Render Today's Focus View
    function renderPlannerTodayView() {
      renderDateStrip();
      renderTodayActionCard();
      renderKhatamProgress();
      renderSevenDayStreak();
    }

    function renderDateStrip() {
      const container = document.getElementById('plannerDateStrip');
      const label = document.getElementById('dateStripCurrentLabel');
      if (!container) return;

      const now = new Date();
      if (label) {
        label.textContent = `${toBnNum(selectedPlannerDate.getDate())} ${GREGORIAN_MONTHS_BN[selectedPlannerDate.getMonth()]}`;
      }

      // 7 days past, today, 3 days future
      const dates = [];
      for (let i = -7; i <= 3; i++) {
        const d = new Date(now);
        d.setDate(d.getDate() + i);
        dates.push(d);
      }

      const dayNames = ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি'];

      container.innerHTML = dates.map(d => {
        const isSelected = d.toDateString() === selectedPlannerDate.toDateString();
        const isToday = d.toDateString() === now.toDateString();
        const dKey = formatDateKey(d);
        const log = plannerState.logs[dKey];
        const isDone = log && log.status === 'completed';
        const dayName = dayNames[d.getDay()];

        return `
          <button onclick="selectPlannerDate('${dKey}')" 
                  class="flex-shrink-0 w-14 py-2 px-1 rounded-2xl flex flex-col items-center justify-center transition border ${
                    isSelected
                      ? 'bg-emerald-700 text-white border-emerald-600 shadow-md ring-2 ring-emerald-500'
                      : isToday
                      ? 'bg-emerald-50 dark:bg-slate-800 text-emerald-800 dark:text-emerald-300 border-emerald-500 font-bold'
                      : 'bg-slate-50 dark:bg-slate-800/60 text-slate-700 dark:text-slate-300 border-slate-200 dark:border-slate-700 hover:border-emerald-400'
                  }">
            <span class="text-[10px] ${isSelected ? 'text-emerald-100' : 'text-slate-500 dark:text-slate-400'}">${dayName}</span>
            <span class="text-sm font-bold font-mono my-0.5">${toBnNum(d.getDate())}</span>
            <span class="text-[10px] ${isDone ? (isSelected ? 'text-gold-300' : 'text-emerald-600 dark:text-emerald-400') : 'text-transparent'}">
              ✓
            </span>
          </button>
        `;
      }).join('');
    }

    window.selectPlannerDate = function(dKey) {
      const parts = dKey.split('-');
      selectedPlannerDate = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
      renderPlannerTodayView();
    };

    function renderTodayActionCard() {
      const headerEl = document.getElementById('selectedDateHeader');
      const toggleBtn = document.getElementById('toggleDayStatusBtn');
      if (!headerEl) return;

      headerEl.textContent = formatTriDateFull(selectedPlannerDate, plannerState.hijriOffset);

      const dKey = formatDateKey(selectedPlannerDate);
      const dayData = plannerState.logs[dKey] || {};
      const isDone = dayData.status === 'completed';

      if (toggleBtn) {
        if (isDone) {
          toggleBtn.className = 'px-3 py-1.5 rounded-xl text-xs font-bold transition flex items-center gap-1.5 bg-emerald-700 text-white shadow-sm';
          toggleBtn.innerHTML = '<span>✓</span><span>পড়া সম্পন্ন</span>';
        } else {
          toggleBtn.className = 'px-3 py-1.5 rounded-xl text-xs font-bold transition flex items-center gap-1.5 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800';
          toggleBtn.innerHTML = '<span>○</span><span>সম্পন্ন চিহ্নিত করুন</span>';
        }
      }

      // Populate input values
      const genInput = document.getElementById('generalTilawatInput');
      if (genInput) genInput.value = dayData.generalTilawat || dayData.dourPara || '';

      const hafInput = document.getElementById('hafizDourInput');
      if (hafInput) hafInput.value = dayData.dourPara || '';

      const sabakInput = document.getElementById('studentSabakInput');
      const sabkiInput = document.getElementById('studentSabkiInput');
      const dourInput = document.getElementById('studentDourInput');
      if (sabakInput) sabakInput.value = dayData.sabak || '';
      if (sabkiInput) sabkiInput.value = dayData.sabki || '';
      if (dourInput) dourInput.value = dayData.studentDour || '';
    }

    // Toggle Status Button Click
    const toggleDayStatusBtn = document.getElementById('toggleDayStatusBtn');
    if (toggleDayStatusBtn) {
      toggleDayStatusBtn.addEventListener('click', () => {
        const dKey = formatDateKey(selectedPlannerDate);
        if (!plannerState.logs[dKey]) plannerState.logs[dKey] = { notes: [] };
        const current = plannerState.logs[dKey].status;
        const newStatus = (current === 'completed') ? 'pending' : 'completed';
        plannerState.logs[dKey].status = newStatus;
        savePlannerData();
        renderPlannerTodayView();
        showToast(newStatus === 'completed' ? 'আলহামদুলিল্লাহ! তিলাওয়াত সম্পন্ন চিহ্নিত করা হয়েছে।' : 'স্ট্যাটাস আপডেট হয়েছে।');
      });
    }

    // Save General Tilawat
    const saveGeneralTilawatBtn = document.getElementById('saveGeneralTilawatBtn');
    if (saveGeneralTilawatBtn) {
      saveGeneralTilawatBtn.addEventListener('click', () => {
        const val = document.getElementById('generalTilawatInput').value.trim();
        const dKey = formatDateKey(selectedPlannerDate);
        if (!plannerState.logs[dKey]) plannerState.logs[dKey] = { notes: [] };
        plannerState.logs[dKey].generalTilawat = val;
        plannerState.logs[dKey].status = 'completed';
        savePlannerData();
        renderPlannerTodayView();
        showToast('আজকের তিলাওয়াত সংরক্ষিত হয়েছে!');
      });
    }

    // Save Hafiz Dour
    const saveHafizDourBtn = document.getElementById('saveHafizDourBtn');
    if (saveHafizDourBtn) {
      saveHafizDourBtn.addEventListener('click', () => {
        const val = document.getElementById('hafizDourInput').value.trim();
        const dKey = formatDateKey(selectedPlannerDate);
        if (!plannerState.logs[dKey]) plannerState.logs[dKey] = { notes: [] };
        plannerState.logs[dKey].dourPara = val;
        plannerState.logs[dKey].status = 'completed';
        savePlannerData();
        renderPlannerTodayView();
        showToast('আজকের দাওর সংরক্ষিত হয়েছে!');
      });
    }

    // Save Student Routine
    const saveStudentRoutineBtn = document.getElementById('saveStudentRoutineBtn');
    if (saveStudentRoutineBtn) {
      saveStudentRoutineBtn.addEventListener('click', () => {
        const dKey = formatDateKey(selectedPlannerDate);
        if (!plannerState.logs[dKey]) plannerState.logs[dKey] = { notes: [] };
        plannerState.logs[dKey].sabak = document.getElementById('studentSabakInput').value.trim();
        plannerState.logs[dKey].sabki = document.getElementById('studentSabkiInput').value.trim();
        plannerState.logs[dKey].studentDour = document.getElementById('studentDourInput').value.trim();
        plannerState.logs[dKey].status = 'completed';
        savePlannerData();
        renderPlannerTodayView();
        showToast('শিক্ষার্থী রুটিন সংরক্ষিত হয়েছে!');
      });
    }

    function renderKhatamProgress() {
      let completedCount = 0;
      Object.keys(plannerState.logs || {}).forEach(k => {
        if (plannerState.logs[k] && plannerState.logs[k].status === 'completed') {
          completedCount++;
        }
      });

      const target = plannerState.targetDays || 30;
      const pct = Math.min(100, Math.round((completedCount / target) * 100));

      const bar = document.getElementById('khatamProgressBar');
      const badge = document.getElementById('khatamPercentBadge');
      const doneText = document.getElementById('khatamCompletedDaysText');
      const targetText = document.getElementById('khatamTargetDaysText');

      if (bar) bar.style.width = pct + '%';
      if (badge) badge.textContent = toBnNum(pct) + '% সম্পন্ন';
      if (doneText) doneText.textContent = `মোট পড়া হয়েছে: ${toBnNum(completedCount)} দিন`;
      if (targetText) targetText.textContent = `টার্গেট: ${toBnNum(target)} দিন`;
    }

    function renderSevenDayStreak() {
      const container = document.getElementById('sevenDayStreakContainer');
      const badge = document.getElementById('streakCountBadge');
      if (!container) return;

      const now = new Date();
      const past7 = [];
      let streakCount = 0;

      for (let i = 6; i >= 0; i--) {
        const d = new Date(now);
        d.setDate(d.getDate() - i);
        const k = formatDateKey(d);
        const isDone = plannerState.logs[k] && plannerState.logs[k].status === 'completed';
        if (isDone) streakCount++;
        past7.push({ date: d, isDone });
      }

      if (badge) badge.textContent = `${toBnNum(streakCount)}/৭ দিন`;

      const dayNames = ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি'];

      container.innerHTML = past7.map(item => `
        <div class="flex flex-col items-center gap-1">
          <div class="w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold ${
            item.isDone
              ? 'bg-emerald-700 text-white shadow-sm'
              : 'bg-slate-200 dark:bg-slate-700 text-slate-400'
          }">
            ${item.isDone ? '✓' : '-'}
          </div>
          <span class="text-[9.5px] text-slate-500">${dayNames[item.date.getDay()]}</span>
        </div>
      `).join('');
    }

    // TAB 2: Roadmap Generator
    function renderPlannerRoadmapView() {
      const startDateInput = document.getElementById('cycleStartDateInput');
      if (startDateInput && !startDateInput.value) {
        startDateInput.value = formatDateKey(new Date());
      }
    }

    const generateCycleBtn = document.getElementById('generateCycleBtn');
    if (generateCycleBtn) {
      generateCycleBtn.addEventListener('click', () => {
        const mode = plannerState.profileMode || 'general';
        const targetDays = parseInt(document.getElementById('cycleTargetDaysSelect').value, 10) || 30;
        const startPara = parseInt(document.getElementById('cycleStartParaInput').value, 10) || 1;
        const startDateVal = document.getElementById('cycleStartDateInput').value;
        const startDate = startDateVal ? new Date(startDateVal) : new Date();

        plannerState.targetDays = targetDays;

        let currPara = startPara;
        let d = new Date(startDate);

        for (let i = 0; i < targetDays; i++) {
          const dKey = formatDateKey(d);
          if (!plannerState.logs[dKey]) plannerState.logs[dKey] = { notes: [] };

          let text = '';
          if (mode === 'general') {
            if (targetDays === 30) {
              const p = ((currPara - 1) % 30) + 1;
              text = `পারা ${toBnNum(p)} (প্রতিদিন ১ পারা)`;
              currPara++;
            } else if (targetDays === 60) {
              const p = (((Math.floor(i / 2)) + startPara - 1) % 30) + 1;
              text = `পারা ${toBnNum(p)} (${i % 2 === 0 ? '১ম ১০ পৃষ্ঠা' : '২য় ১০ পৃষ্ঠা'})`;
            } else {
              const p = ((currPara - 1) % 30) + 1;
              text = `পারা ${toBnNum(p)}`;
              currPara++;
            }
            plannerState.logs[dKey].generalTilawat = text;
          } else {
            const p = ((currPara - 1) % 30) + 1;
            text = `পারা ${toBnNum(p)}`;
            currPara++;
            plannerState.logs[dKey].dourPara = text;
          }

          if (!plannerState.logs[dKey].status) {
            plannerState.logs[dKey].status = 'pending';
          }
          d.setDate(d.getDate() + 1);
        }

        savePlannerData();

        const summaryBox = document.getElementById('cycleSummaryBox');
        const summaryText = document.getElementById('cycleSummaryText');
        if (summaryBox && summaryText) {
          summaryBox.classList.remove('hidden');
          summaryText.textContent = `আলহামদুলিল্লাহ! আপনার নির্বাচন অনুযায়ী আগামী ${toBnNum(targetDays)} দিনের রোডম্যাপ প্রস্তুত করা হয়েছে। প্রতিদিনের টার্গেট আজকের ড্যাশবোর্ডে দেখতে পাবেন।`;
        }

        showToast('রোডম্যাপ সফলভাবে সাজানো হয়েছে!');
      });
    }

    // TAB 3: Quranic Diary & Notes
    function renderPlannerDiaryView() {
      const container = document.getElementById('allNotesListContainer');
      const countBadge = document.getElementById('totalNotesCountBadge');
      if (!container) return;

      const allNotes = [];
      Object.keys(plannerState.logs || {}).forEach(dKey => {
        const item = plannerState.logs[dKey];
        if (item && item.notes && item.notes.length > 0) {
          item.notes.forEach((n, idx) => {
            allNotes.push({ ...n, dateKey: dKey, originalIdx: idx });
          });
        }
      });

      if (countBadge) countBadge.textContent = `${toBnNum(allNotes.length)} টি`;

      if (allNotes.length === 0) {
        container.innerHTML = `
          <div class="p-8 text-center bg-slate-50 dark:bg-slate-800 rounded-2xl border border-slate-200 dark:border-slate-700 text-slate-400 text-xs">
            এখনও কোনো নোট সংরক্ষণ করা হয়নি।<br>তিলাওয়াত বা হিফজের সময় ভুল আয়াত বা অনুভূতি টুকে রাখুন।
          </div>
        `;
        return;
      }

      allNotes.sort((a, b) => (b.id || 0) - (a.id || 0));

      container.innerHTML = allNotes.map(n => `
        <div class="p-3 rounded-2xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 flex items-center justify-between gap-3 shadow-sm">
          <div class="flex-1">
            <div class="flex items-center gap-2 mb-1">
              <span class="text-xs bg-emerald-700 text-white font-bold px-2.5 py-0.5 rounded-full font-mono">পৃষ্ঠা ${toBnNum(n.page)}</span>
              <span class="text-[10px] text-slate-500 font-mono">${n.dateKey}</span>
            </div>
            <p class="text-xs text-slate-800 dark:text-slate-200 font-bengali leading-relaxed">${n.text}</p>
          </div>
          <div class="flex items-center gap-2 shrink-0">
            <button onclick="jumpToPageFromNote(${n.page})" class="px-3 py-1.5 bg-emerald-700 hover:bg-emerald-600 text-white rounded-xl text-xs font-semibold transition shadow-sm">
              📖 পৃষ্ঠায় যান
            </button>
            <button onclick="deleteDiaryNote('${n.dateKey}', ${n.id})" class="p-1.5 text-rose-500 hover:text-rose-700 transition" title="মুছে ফেলুন">
              ✕
            </button>
          </div>
        </div>
      `).join('');
    }

    const addSelfCorrectionBtn = document.getElementById('addSelfCorrectionBtn');
    if (addSelfCorrectionBtn) {
      addSelfCorrectionBtn.addEventListener('click', () => {
        const pageVal = parseInt(document.getElementById('notePageInput').value, 10);
        const textVal = document.getElementById('noteTextInput').value.trim();

        if (!pageVal || pageVal < 1 || pageVal > 612) {
          showToast('সঠিক পৃষ্ঠা নম্বর দিন (১ থেকে ৬১২)');
          return;
        }
        if (!textVal) {
          showToast('নোটের বিবরণ লিখুন');
          return;
        }

        const dKey = formatDateKey(selectedPlannerDate);
        if (!plannerState.logs[dKey]) plannerState.logs[dKey] = { notes: [] };
        if (!plannerState.logs[dKey].notes) plannerState.logs[dKey].notes = [];

        plannerState.logs[dKey].notes.push({
          id: Date.now(),
          page: pageVal,
          text: textVal
        });

        savePlannerData();
        document.getElementById('noteTextInput').value = '';
        renderPlannerDiaryView();
        showToast('নোট সফলভাবে যুক্ত হয়েছে!');
      });
    }

    window.jumpToPageFromNote = function(pageNum) {
      closePlannerSheet();
      goToPage(pageNum);
    };

    window.deleteDiaryNote = function(dateKey, noteId) {
      if (plannerState.logs[dateKey] && plannerState.logs[dateKey].notes) {
        plannerState.logs[dateKey].notes = plannerState.logs[dateKey].notes.filter(n => n.id !== noteId);
        savePlannerData();
        renderPlannerDiaryView();
        showToast('নোট মুছে ফেলা হয়েছে');
      }
    };

    // SETTINGS DRAWER / OVERLAY LOGIC
    const openPlannerSettingsBtn = document.getElementById('openPlannerSettingsBtn');
    const closePlannerSettingsBtn = document.getElementById('closePlannerSettingsBtn');
    const plannerSettingsModal = document.getElementById('plannerSettingsModal');
    const savePlannerSettingsBtn = document.getElementById('savePlannerSettingsBtn');

    let tempSelectedMode = plannerState.profileMode || 'general';

    function openPlannerSettings() {
      tempSelectedMode = plannerState.profileMode || 'general';
      updateSettingsModalUI();
      if (plannerSettingsModal) plannerSettingsModal.classList.remove('hidden');
    }

    function closePlannerSettings() {
      if (plannerSettingsModal) plannerSettingsModal.classList.add('hidden');
    }

    function updateSettingsModalUI() {
      document.querySelectorAll('.planner-mode-btn').forEach(btn => {
        const m = btn.getAttribute('data-mode');
        if (m === tempSelectedMode) {
          btn.className = 'planner-mode-btn p-3 rounded-2xl border-2 border-emerald-600 bg-emerald-50 dark:bg-emerald-950/40 text-left transition flex flex-col gap-1';
        } else {
          btn.className = 'planner-mode-btn p-3 rounded-2xl border border-slate-200 dark:border-slate-700 text-left transition flex flex-col gap-1 hover:border-slate-400';
        }
      });

      const remToggle = document.getElementById('plannerReminderToggle');
      const remTime = document.getElementById('plannerReminderTimeInput');
      if (remToggle) remToggle.checked = !!plannerState.reminderEnabled;
      if (remTime) remTime.value = plannerState.reminderTime || '06:00';

      const offsetLabel = document.getElementById('hijriOffsetLabel');
      if (offsetLabel) {
        offsetLabel.textContent = `${plannerState.hijriOffset > 0 ? '+' : ''}${toBnNum(plannerState.hijriOffset)} দিন`;
      }
      document.querySelectorAll('.offset-btn').forEach(b => {
        const off = parseInt(b.getAttribute('data-offset'), 10);
        if (off === plannerState.hijriOffset) {
          b.className = 'offset-btn flex-1 py-1.5 rounded-xl border text-xs font-semibold bg-emerald-600 text-white';
        } else {
          b.className = 'offset-btn flex-1 py-1.5 rounded-xl border text-xs font-semibold';
        }
      });
    }

    if (openPlannerSettingsBtn) openPlannerSettingsBtn.addEventListener('click', openPlannerSettings);
    if (closePlannerSettingsBtn) closePlannerSettingsBtn.addEventListener('click', closePlannerSettings);

    document.querySelectorAll('.planner-mode-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        tempSelectedMode = btn.getAttribute('data-mode');
        updateSettingsModalUI();
      });
    });

    document.querySelectorAll('.offset-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        plannerState.hijriOffset = parseInt(btn.getAttribute('data-offset'), 10);
        updateSettingsModalUI();
      });
    });

    if (savePlannerSettingsBtn) {
      savePlannerSettingsBtn.addEventListener('click', () => {
        plannerState.profileMode = tempSelectedMode;
        const remToggle = document.getElementById('plannerReminderToggle');
        const remTime = document.getElementById('plannerReminderTimeInput');
        if (remToggle) plannerState.reminderEnabled = remToggle.checked;
        if (remTime) plannerState.reminderTime = remTime.value;

        savePlannerData();
        closePlannerSettings();
        updatePlannerModeUI();
        renderTodayTriDate();
        switchPlannerTab(plannerState.activeTab || 'today');
        showToast('প্ল্যানার সেটিংস সফলভাবে সংরক্ষিত হয়েছে!');
      });
    }

    // Backup & Restore
    const backupDownloadBtn = document.getElementById('backupDownloadBtn');
    if (backupDownloadBtn) {
      backupDownloadBtn.addEventListener('click', () => {
        const dataStr = 'data:text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(plannerState, null, 2));
        const dl = document.createElement('a');
        dl.setAttribute('href', dataStr);
        dl.setAttribute('download', `quran_planner_backup_${formatDateKey(new Date())}.json`);
        document.body.appendChild(dl);
        dl.click();
        dl.remove();
        showToast('ব্যাকআপ ডাউনলোড সম্পন্ন হয়েছে!');
      });
    }

    const restoreFileInput = document.getElementById('restoreFileInput');
    if (restoreFileInput) {
      restoreFileInput.addEventListener('change', (e) => {
        const file = e.target.files[0];
        if (!file) return;
        const reader = new FileReader();
        reader.onload = (evt) => {
          try {
            const restored = JSON.parse(evt.target.result);
            if (restored && typeof restored === 'object') {
              plannerState = { ...plannerState, ...restored };
              savePlannerData();
              updatePlannerModeUI();
              renderTodayTriDate();
              switchPlannerTab(plannerState.activeTab || 'today');
              showToast('ব্যাকআপ সফলভাবে রিস্টোর হয়েছে!');
            }
          } catch (err) {
            showToast('ফাইলের ফরম্যাট সঠিক নয়');
          }
        };
        reader.readAsText(file);
      });
    }

    // Reset Progress
    const resetPlannerProgressBtn = document.getElementById('resetPlannerProgressBtn');
    if (resetPlannerProgressBtn) {
      resetPlannerProgressBtn.addEventListener('click', () => {
        if (confirm('আপনি কি সকল ট্র্যাকিং হিসেব রিসেট করতে চান?')) {
          plannerState.logs = {};
          savePlannerData();
          renderPlannerTodayView();
          closePlannerSettings();
          showToast('প্ল্যানার প্রগ্রেস রিসেট করা হয়েছে!');
        }
      });
    }

    // Initialize planner state
    loadPlannerData();

    // ==========================================
    // WUDU & PURITY GATEWAY SLIDER INTERACTION
    // ==========================================
    (function initWuduGateway() {
      const modal = document.getElementById('wuduGatewayModal');
      const track = document.getElementById('wuduSliderTrack');
      const thumb = document.getElementById('wuduSliderThumb');
      const fill = document.getElementById('wuduSliderFill');
      const text = document.getElementById('wuduSliderText');
      const skipBtn = document.getElementById('skipWuduGatewayBtn');

      if (!modal || !track || !thumb) return;

      // Check if dismissed in this session
      if (sessionStorage.getItem('wuduGatewayDismissed') === 'true') {
        modal.classList.add('hidden');
        return;
      }

      let isDragging = false;
      let startX = 0;
      let currentOffset = 0;

      function getMaxDrag() {
        return Math.max(0, track.clientWidth - thumb.clientWidth - 8);
      }

      function updateDrag(x) {
        const maxDrag = getMaxDrag();
        currentOffset = Math.max(0, Math.min(x, maxDrag));
        thumb.style.transform = `translateX(${currentOffset}px)`;
        if (fill) fill.style.width = `${currentOffset + thumb.clientWidth}px`;
        if (text) {
          const progress = maxDrag > 0 ? (currentOffset / maxDrag) : 0;
          text.style.opacity = Math.max(0, 1 - progress * 1.5);
        }
      }

      function confirmPurityAndDismiss() {
        thumb.innerHTML = '✓';
        modal.classList.add('opacity-0');
        modal.style.pointerEvents = 'none';
        sessionStorage.setItem('wuduGatewayDismissed', 'true');
        setTimeout(() => {
          modal.classList.add('hidden');
        }, 350);
      }

      function resetSlider() {
        thumb.style.transition = 'transform 0.25s cubic-bezier(0.175, 0.885, 0.32, 1.275)';
        if (fill) fill.style.transition = 'width 0.25s ease';
        currentOffset = 0;
        thumb.style.transform = 'translateX(0px)';
        if (fill) fill.style.width = '48px';
        if (text) text.style.opacity = '1';
        setTimeout(() => {
          thumb.style.transition = '';
          if (fill) fill.style.transition = '';
        }, 250);
      }

      // Mouse drag handlers
      thumb.addEventListener('mousedown', (e) => {
        isDragging = true;
        startX = e.clientX - currentOffset;
        e.preventDefault();
      });

      window.addEventListener('mousemove', (e) => {
        if (!isDragging) return;
        updateDrag(e.clientX - startX);
      });

      window.addEventListener('mouseup', () => {
        if (!isDragging) return;
        isDragging = false;
        const maxDrag = getMaxDrag();
        if (currentOffset >= maxDrag * 0.75) {
          updateDrag(maxDrag);
          confirmPurityAndDismiss();
        } else {
          resetSlider();
        }
      });

      // Touch drag handlers
      thumb.addEventListener('touchstart', (e) => {
        isDragging = true;
        startX = e.touches[0].clientX - currentOffset;
      }, { passive: true });

      window.addEventListener('touchmove', (e) => {
        if (!isDragging) return;
        updateDrag(e.touches[0].clientX - startX);
      }, { passive: true });

      window.addEventListener('touchend', () => {
        if (!isDragging) return;
        isDragging = false;
        const maxDrag = getMaxDrag();
        if (currentOffset >= maxDrag * 0.75) {
          updateDrag(maxDrag);
          confirmPurityAndDismiss();
        } else {
          resetSlider();
        }
      });

      if (skipBtn) {
        skipBtn.addEventListener('click', confirmPurityAndDismiss);
      }
    })();
'''

# Replace HTML Block
idx1 = content.find('<!-- 4. Huffaz Routine & Tri-Calendar Modal -->')
idx2 = content.find('<!-- 5. Quran Global Search Modal')
if idx1 == -1 or idx2 == -1:
    print('ERROR: markers for HTML block not found!')
    exit(1)

content_updated = content[:idx1] + wudu_and_planner_html + '\n  ' + content[idx2:]

# Replace JS Block
js_idx1 = content_updated.find('// PLANNER STATE & DATA MANAGEMENT')
js_idx2 = content_updated.find('// GLOBAL QURAN SEARCH ENGINE')
if js_idx1 == -1 or js_idx2 == -1:
    print('ERROR: markers for JS block not found!')
    exit(1)

final_content = content_updated[:js_idx1] + planner_js.strip() + '\n\n    ' + content_updated[js_idx2:]

# Write to both docs/reader.html and landing/reader.html
with open('docs/reader.html', 'w', encoding='utf-8') as f:
    f.write(final_content)

with open('landing/reader.html', 'w', encoding='utf-8') as f:
    f.write(final_content)

print('SUCCESS: updated docs/reader.html and landing/reader.html')
