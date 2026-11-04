import os

with open('docs/reader.html', 'r', encoding='utf-8') as f:
    content = f.read()

# Tab 1 HTML Replacement
tab1_replacement = '''        <!-- TAB 1: Today's Focus -->
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

          <!-- 2. Today's Action Card (Integer Paras & Pages Input) -->
          <div id="selectedDayCard" class="p-4 rounded-2xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 shadow-sm space-y-3.5">
            <div class="flex items-center justify-between pb-2 border-b border-slate-200 dark:border-slate-700">
              <div>
                <span class="text-[11px] font-bold text-gold-600 dark:text-gold-400">নির্বাচিত দিনের হিসাব</span>
                <h3 id="selectedDateHeader" class="text-sm sm:text-base font-bold text-slate-900 dark:text-white"></h3>
              </div>
              <button id="toggleDayStatusBtn" class="px-3 py-1.5 rounded-xl text-xs font-bold transition flex items-center gap-1.5">
                <!-- Status icon + text populated via JS -->
              </button>
            </div>

            <!-- Integer Input Section: Paras and Pages -->
            <div class="space-y-2.5">
              <div class="grid grid-cols-2 gap-2.5">
                <!-- Paras read today -->
                <div class="p-3 rounded-2xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-700">
                  <label class="text-[11px] font-bold text-slate-700 dark:text-slate-300 block mb-1">
                    পারা পড়েছেন (০-৩০):
                  </label>
                  <div class="flex items-center gap-1">
                    <button type="button" id="decParasBtn" class="w-8 h-8 rounded-xl bg-slate-200 dark:bg-slate-700 font-bold text-base hover:bg-slate-300 transition flex items-center justify-center select-none">-</button>
                    <input type="number" id="dayParasInput" min="0" max="30" value="0" 
                           class="flex-1 text-center py-1.5 px-1 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-sm font-bold font-mono">
                    <button type="button" id="incParasBtn" class="w-8 h-8 rounded-xl bg-slate-200 dark:bg-slate-700 font-bold text-base hover:bg-slate-300 transition flex items-center justify-center select-none">+</button>
                  </div>
                  <span class="text-[10px] text-slate-500 mt-1 block text-center">(১ পারা = ২০ পৃষ্ঠা)</span>
                </div>

                <!-- Pages read today -->
                <div class="p-3 rounded-2xl bg-slate-50 dark:bg-slate-900/60 border border-slate-200 dark:border-slate-700">
                  <label class="text-[11px] font-bold text-slate-700 dark:text-slate-300 block mb-1">
                    পৃষ্ঠা পড়েছেন (০-৬১২):
                  </label>
                  <div class="flex items-center gap-1">
                    <button type="button" id="decPagesBtn" class="w-8 h-8 rounded-xl bg-slate-200 dark:bg-slate-700 font-bold text-base hover:bg-slate-300 transition flex items-center justify-center select-none">-</button>
                    <input type="number" id="dayPagesInput" min="0" max="612" value="0" 
                           class="flex-1 text-center py-1.5 px-1 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-sm font-bold font-mono">
                    <button type="button" id="incPagesBtn" class="w-8 h-8 rounded-xl bg-slate-200 dark:bg-slate-700 font-bold text-base hover:bg-slate-300 transition flex items-center justify-center select-none">+</button>
                  </div>
                  <span class="text-[10px] text-slate-500 mt-1 block text-center">অতিরিক্ত বা সরাসরি পৃষ্ঠা</span>
                </div>
              </div>

              <!-- Quick Add Chips -->
              <div class="flex items-center gap-1.5 overflow-x-auto pb-1 no-scrollbar text-xs">
                <span class="text-[10px] text-slate-500 shrink-0 font-medium">কুইক এড:</span>
                <button type="button" onclick="quickAddRead(0, 5)" class="px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-emerald-100 text-emerald-800 dark:text-emerald-300 text-[11px] font-semibold border border-slate-200 dark:border-slate-700 transition shrink-0">+৫ পৃষ্ঠা</button>
                <button type="button" onclick="quickAddRead(0, 10)" class="px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-emerald-100 text-emerald-800 dark:text-emerald-300 text-[11px] font-semibold border border-slate-200 dark:border-slate-700 transition shrink-0">+১০ পৃষ্ঠা</button>
                <button type="button" onclick="quickAddRead(1, 0)" class="px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-emerald-100 text-emerald-800 dark:text-emerald-300 text-[11px] font-semibold border border-slate-200 dark:border-slate-700 transition shrink-0">+১ পারা</button>
                <button type="button" onclick="quickAddRead(2, 0)" class="px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-emerald-100 text-emerald-800 dark:text-emerald-300 text-[11px] font-semibold border border-slate-200 dark:border-slate-700 transition shrink-0">+২ পারা</button>
                <button type="button" onclick="resetDayInputs()" class="px-2 py-1 rounded-lg text-rose-500 hover:bg-rose-50 text-[11px] transition shrink-0">রিসেট</button>
              </div>

              <!-- Live Total Calculation Banner -->
              <div class="p-2.5 rounded-xl bg-emerald-50 dark:bg-emerald-950/60 border border-emerald-500/30 flex items-center justify-between text-xs">
                <span class="text-slate-700 dark:text-slate-300 font-medium">আজকের সর্বমোট তিলাওয়াত:</span>
                <span id="dayTotalCalculatedText" class="font-bold text-emerald-800 dark:text-emerald-300 font-mono text-sm">০ পৃষ্ঠা (০.০ পারা)</span>
              </div>

              <!-- Note / Details and Save Action -->
              <div class="flex items-center gap-2 pt-1">
                <input type="text" id="dayNoteDetailsInput" placeholder="বিবরণ (ঐচ্ছিক, যেমন: ১ থেকে ১০ পারা)" 
                       class="flex-1 px-3 py-2 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-xs font-bengali">
                <button id="saveDayProgressBtn" class="px-4 py-2 bg-emerald-700 hover:bg-emerald-600 text-white rounded-xl text-xs font-bold transition shrink-0 shadow-sm">
                  সংরক্ষণ করুন
                </button>
              </div>
            </div>
          </div>

          <!-- 3. Khatam Progress Card (Valid Percentage & Actual Pages Calculation) -->
          <div class="p-4 rounded-2xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 shadow-sm space-y-3">
            <div class="flex items-center justify-between">
              <div>
                <span class="text-xs font-bold text-slate-800 dark:text-slate-200">চলতি খতমের অগ্রগতি (প্রকৃত পৃষ্ঠা ট্র্যাকিং)</span>
                <p class="text-[11px] text-slate-500 dark:text-slate-400">মোট ৬১২ পৃষ্ঠার হাফেজী কুরআন</p>
              </div>
              <span id="khatamPercentBadge" class="text-xs bg-emerald-100 dark:bg-emerald-950 text-emerald-800 dark:text-emerald-300 font-bold px-2.5 py-1 rounded-full font-mono">০.০% সম্পন্ন</span>
            </div>

            <!-- Visual Progress Bar -->
            <div class="w-full bg-slate-100 dark:bg-slate-700 rounded-full h-3 overflow-hidden p-0.5">
              <div id="khatamProgressBar" class="bg-gradient-to-r from-emerald-600 to-teal-500 h-2 rounded-full transition-all duration-300" style="width: 0%"></div>
            </div>

            <!-- Numerical Stats Grid -->
            <div class="grid grid-cols-2 sm:grid-cols-3 gap-2 pt-0.5 text-center">
              <div class="p-2 rounded-xl bg-slate-50 dark:bg-slate-900/50 border border-slate-100 dark:border-slate-700/60">
                <span class="text-[10px] text-slate-500 block">মোট পড়া হয়েছে</span>
                <span id="statPagesReadText" class="text-xs font-bold text-emerald-700 dark:text-emerald-400 font-mono">০ / ৬১২ পৃষ্ঠা</span>
              </div>
              <div class="p-2 rounded-xl bg-slate-50 dark:bg-slate-900/50 border border-slate-100 dark:border-slate-700/60">
                <span class="text-[10px] text-slate-500 block">বাকি আছে</span>
                <span id="statPagesRemainingText" class="text-xs font-bold text-amber-600 dark:text-amber-400 font-mono">৬১২ পৃষ্ঠা (৩০ পারা)</span>
              </div>
              <div class="col-span-2 sm:col-span-1 p-2 rounded-xl bg-slate-50 dark:bg-slate-900/50 border border-slate-100 dark:border-slate-700/60">
                <span class="text-[10px] text-slate-500 block">লক্ষ্য পূরণে দৈনিক প্রয়োজন</span>
                <span id="statDailyRequiredText" class="text-xs font-bold text-slate-800 dark:text-slate-200 font-mono">২০ পৃষ্ঠা/দিন</span>
              </div>
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
'''

# Tab 2 HTML Replacement (Target Roadmap with Adaptive Pace)
tab2_replacement = '''        <!-- TAB 2: Roadmap & Plan -->
        <div id="plannerViewRoadmap" class="hidden space-y-4">
          <div class="p-4 rounded-2xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 space-y-3">
            <h3 class="text-sm font-bold text-slate-900 dark:text-white flex items-center gap-2">
              <span id="cycleViewIcon">🎯</span>
              <span id="cycleViewTitle">খতম ও দাওর রোডম্যাপ নির্ধারণ</span>
            </h3>
            <p id="cycleViewDesc" class="text-xs text-slate-600 dark:text-slate-400 leading-relaxed">
              আপনার সুবিধাজনক সময়সীমা নির্ধারণ করুন। আপনি কতটুকু পড়েছেন তার ওপর ভিত্তি করে অ্যাপ স্বয়ংক্রিয়ভাবে বাকি পড়ার লক্ষ্য বণ্টন করে দেবে।
            </p>

            <div class="space-y-3 pt-1">
              <div>
                <label id="cycleTargetDaysLabel" class="text-xs font-bold text-slate-700 dark:text-slate-300">টার্গেট সময়সীমা (দিন):</label>
                <select id="cycleTargetDaysSelect" class="w-full mt-1 px-3 py-2 rounded-xl border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 text-xs font-bengali">
                  <option value="5">৫ দিনে খতম (দ্রুত দাওর/খতম)</option>
                  <option value="10">১০ দিনে খতম (প্রতিদিন ৩ পারা / ৬০ পৃষ্ঠা)</option>
                  <option value="15">১৫ দিনে খতম (প্রতিদিন ২ পারা / ৪০ পৃষ্ঠা)</option>
                  <option value="20">২০ দিনে খতম (প্রতিদিন ১.৫ পারা / ৩০ পৃষ্ঠা)</option>
                  <option value="30" selected>৩০ দিনে খতম (প্রতিদিন ১ পারা / ২০ পৃষ্ঠা)</option>
                  <option value="60">৬০ দিনে খতম (প্রতিদিন ১০ পৃষ্ঠা)</option>
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
            <div class="font-bold text-emerald-800 dark:text-emerald-300">💡 ডায়নামিক হিসাব পরামর্শ:</div>
            <p>১. কোনো দিন বেশি বা কম পড়া হলে স্বয়ংক্রিয়ভাবে পরের দিনগুলোর পড়ার টার্গেট সমন্বিত হবে।</p>
            <p>২. এক বসায় সম্ভব না হলে ৫ ওয়াক্ত নামাজের পর ৪ পৃষ্ঠা করে পড়লে দিনে ১ পারা শেষ হয়।</p>
            <p>৩. মোট ৬১২ পৃষ্ঠার হাফেজী কুরআন সমাপ্ত হলে স্বয়ংক্রিয়ভাবে ১০০% খতম সফল হবে।</p>
          </div>
        </div>
'''

# JavaScript logic replacement with rigorous integer validation and math
planner_js = '''    // ==========================================
    // PLANNER STATE & DATA MANAGEMENT (Integer & Valid Math Engine)
    // ==========================================
    const PLANNER_STORAGE_KEY = 'quran_huffaz_planner_v3';
    const TOTAL_QURAN_PAGES = 612;
    const TOTAL_QURAN_PARAS = 30;
    const PAGES_PER_PARA = 20;

    let plannerState = {
      profileMode: 'general', // 'general' | 'student' | 'hafiz'
      hijriOffset: 0,
      activeTab: 'today', // 'today' | 'roadmap' | 'diary'
      targetDays: 30,
      reminderEnabled: false,
      reminderTime: '06:00',
      logs: {} // dateKey -> { parasRead: 0, pagesRead: 0, totalDayPages: 0, generalTilawat: '', status: 'completed'|'pending', notes: [] }
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

    // Mathematical Calculation Engine
    function calculateKhatamStats() {
      let totalPagesRead = 0;
      let activeDaysCount = 0;

      Object.keys(plannerState.logs || {}).forEach(k => {
        const item = plannerState.logs[k];
        if (item) {
          let dayP = 0;
          if (typeof item.totalDayPages === 'number' && item.totalDayPages > 0) {
            dayP = item.totalDayPages;
          } else {
            const pr = parseInt(item.parasRead, 10) || 0;
            const pg = parseInt(item.pagesRead, 10) || 0;
            dayP = (pr * PAGES_PER_PARA) + pg;
          }

          if (dayP > 0) {
            totalPagesRead += dayP;
            activeDaysCount++;
          } else if (item.status === 'completed') {
            activeDaysCount++;
          }
        }
      });

      // Capped at 612 pages for Khatam completion
      const cappedPages = Math.min(TOTAL_QURAN_PAGES, totalPagesRead);
      const percent = ((cappedPages / TOTAL_QURAN_PAGES) * 100);
      const remainingPages = Math.max(0, TOTAL_QURAN_PAGES - cappedPages);
      const totalParas = (cappedPages / 20.4).toFixed(1);
      const remainingParas = (remainingPages / 20.4).toFixed(1);

      const targetDays = plannerState.targetDays || 30;
      const remainingDays = Math.max(1, targetDays - activeDaysCount);
      const dailyRequired = remainingPages > 0 ? Math.ceil(remainingPages / remainingDays) : 0;

      return {
        totalPagesRead: cappedPages,
        rawTotalPages: totalPagesRead,
        totalParas,
        percent: percent.toFixed(1),
        remainingPages,
        remainingParas,
        activeDaysCount,
        targetDays,
        remainingDays,
        dailyRequired,
        isCompleted: cappedPages >= TOTAL_QURAN_PAGES
      };
    }

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
        const isDone = log && (log.status === 'completed' || (log.totalDayPages && log.totalDayPages > 0));
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

      const paras = parseInt(dayData.parasRead, 10) || 0;
      const pages = parseInt(dayData.pagesRead, 10) || 0;
      const totalPages = (typeof dayData.totalDayPages === 'number') ? dayData.totalDayPages : (paras * PAGES_PER_PARA) + pages;
      const isDone = dayData.status === 'completed' || totalPages > 0;

      // Update Inputs
      const parasInput = document.getElementById('dayParasInput');
      const pagesInput = document.getElementById('dayPagesInput');
      const detailsInput = document.getElementById('dayNoteDetailsInput');

      if (parasInput) parasInput.value = paras;
      if (pagesInput) pagesInput.value = pages;
      if (detailsInput) detailsInput.value = dayData.generalTilawat || '';

      updateLiveTotalDisplay();

      if (toggleBtn) {
        if (isDone) {
          toggleBtn.className = 'px-3 py-1.5 rounded-xl text-xs font-bold transition flex items-center gap-1.5 bg-emerald-700 text-white shadow-sm';
          toggleBtn.innerHTML = '<span>✓</span><span>পড়া সম্পন্ন</span>';
        } else {
          toggleBtn.className = 'px-3 py-1.5 rounded-xl text-xs font-bold transition flex items-center gap-1.5 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800';
          toggleBtn.innerHTML = '<span>○</span><span>সম্পন্ন চিহ্নিত করুন</span>';
        }
      }
    }

    function updateLiveTotalDisplay() {
      const parasInput = document.getElementById('dayParasInput');
      const pagesInput = document.getElementById('dayPagesInput');
      const displayEl = document.getElementById('dayTotalCalculatedText');

      if (!displayEl) return;

      const paras = Math.max(0, Math.min(30, parseInt(parasInput ? parasInput.value : 0, 10) || 0));
      const pages = Math.max(0, Math.min(612, parseInt(pagesInput ? pagesInput.value : 0, 10) || 0));
      const total = (paras * PAGES_PER_PARA) + pages;
      const parasFraction = (total / 20.4).toFixed(1);

      displayEl.textContent = `${toBnNum(total)} পৃষ্ঠা (${toBnNum(parasFraction)} পারা)`;
    }

    // Input listeners for live calculation
    const dayParasInput = document.getElementById('dayParasInput');
    const dayPagesInput = document.getElementById('dayPagesInput');

    if (dayParasInput) dayParasInput.addEventListener('input', updateLiveTotalDisplay);
    if (dayPagesInput) dayPagesInput.addEventListener('input', updateLiveTotalDisplay);

    // Steppers
    const decParasBtn = document.getElementById('decParasBtn');
    const incParasBtn = document.getElementById('incParasBtn');
    const decPagesBtn = document.getElementById('decPagesBtn');
    const incPagesBtn = document.getElementById('incPagesBtn');

    if (decParasBtn && dayParasInput) {
      decParasBtn.addEventListener('click', () => {
        let v = parseInt(dayParasInput.value, 10) || 0;
        if (v > 0) dayParasInput.value = v - 1;
        updateLiveTotalDisplay();
      });
    }
    if (incParasBtn && dayParasInput) {
      incParasBtn.addEventListener('click', () => {
        let v = parseInt(dayParasInput.value, 10) || 0;
        if (v < 30) dayParasInput.value = v + 1;
        updateLiveTotalDisplay();
      });
    }
    if (decPagesBtn && dayPagesInput) {
      decPagesBtn.addEventListener('click', () => {
        let v = parseInt(dayPagesInput.value, 10) || 0;
        if (v > 0) dayPagesInput.value = v - 1;
        updateLiveTotalDisplay();
      });
    }
    if (incPagesBtn && dayPagesInput) {
      incPagesBtn.addEventListener('click', () => {
        let v = parseInt(dayPagesInput.value, 10) || 0;
        if (v < 612) dayPagesInput.value = v + 1;
        updateLiveTotalDisplay();
      });
    }

    window.quickAddRead = function(parasAdd, pagesAdd) {
      if (dayParasInput && parasAdd) {
        let cur = parseInt(dayParasInput.value, 10) || 0;
        dayParasInput.value = Math.min(30, cur + parasAdd);
      }
      if (dayPagesInput && pagesAdd) {
        let cur = parseInt(dayPagesInput.value, 10) || 0;
        dayPagesInput.value = Math.min(612, cur + pagesAdd);
      }
      updateLiveTotalDisplay();
    };

    window.resetDayInputs = function() {
      if (dayParasInput) dayParasInput.value = 0;
      if (dayPagesInput) dayPagesInput.value = 0;
      updateLiveTotalDisplay();
    };

    // Save Day Progress
    const saveDayProgressBtn = document.getElementById('saveDayProgressBtn');
    if (saveDayProgressBtn) {
      saveDayProgressBtn.addEventListener('click', () => {
        const parasVal = parseInt(document.getElementById('dayParasInput').value, 10) || 0;
        const pagesVal = parseInt(document.getElementById('dayPagesInput').value, 10) || 0;
        const detailsVal = (document.getElementById('dayNoteDetailsInput').value || '').trim();

        if (parasVal < 0 || parasVal > 30) {
          showToast('পারা সংখ্যা ০ থেকে ৩০ এর মধ্যে হতে হবে');
          return;
        }
        if (pagesVal < 0 || pagesVal > 612) {
          showToast('পৃষ্ঠা সংখ্যা ০ থেকে ৬১২ এর মধ্যে হতে হবে');
          return;
        }

        const totalDay = (parasVal * PAGES_PER_PARA) + pagesVal;
        const dKey = formatDateKey(selectedPlannerDate);

        if (!plannerState.logs[dKey]) plannerState.logs[dKey] = { notes: [] };

        plannerState.logs[dKey].parasRead = parasVal;
        plannerState.logs[dKey].pagesRead = pagesVal;
        plannerState.logs[dKey].totalDayPages = totalDay;
        plannerState.logs[dKey].generalTilawat = detailsVal || `${toBnNum(totalDay)} পৃষ্ঠা তিলাওয়াত`;
        plannerState.logs[dKey].status = totalDay > 0 ? 'completed' : 'pending';

        savePlannerData();
        renderPlannerTodayView();
        showToast(totalDay > 0 
          ? `আলহামদুলিল্লাহ! ${toBnNum(totalDay)} পৃষ্ঠা তিলাওয়াত সফলভাবে সংরক্ষিত হয়েছে।`
          : 'হিসাব আপডেট করা হয়েছে।');
      });
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
        showToast(newStatus === 'completed' 
          ? 'আলহামদুলিল্লাহ! দিনটি সম্পন্ন হিসেবে চিহ্নিত করা হয়েছে।' 
          : 'স্ট্যাটাস পরিবর্তন করা হয়েছে।');
      });
    }

    function renderKhatamProgress() {
      const stats = calculateKhatamStats();

      const bar = document.getElementById('khatamProgressBar');
      const badge = document.getElementById('khatamPercentBadge');
      const readText = document.getElementById('statPagesReadText');
      const remText = document.getElementById('statPagesRemainingText');
      const dailyText = document.getElementById('statDailyRequiredText');

      if (bar) bar.style.width = stats.percent + '%';
      if (badge) {
        badge.textContent = `${toBnNum(stats.percent)}% সম্পন্ন`;
        if (stats.isCompleted) {
          badge.className = 'text-xs bg-gold-400 text-emerald-950 font-bold px-2.5 py-1 rounded-full font-mono';
        } else {
          badge.className = 'text-xs bg-emerald-100 dark:bg-emerald-950 text-emerald-800 dark:text-emerald-300 font-bold px-2.5 py-1 rounded-full font-mono';
        }
      }

      if (readText) {
        readText.textContent = `${toBnNum(stats.totalPagesRead)} / ${toBnNum(TOTAL_QURAN_PAGES)} পৃষ্ঠা (${toBnNum(stats.totalParas)} পারা)`;
      }

      if (remText) {
        if (stats.isCompleted) {
          remText.textContent = 'আলহামদুলিল্লাহ! খতম সম্পন্ন!';
          remText.className = 'text-xs font-bold text-emerald-600 dark:text-emerald-400 font-mono';
        } else {
          remText.textContent = `${toBnNum(stats.remainingPages)} পৃষ্ঠা (${toBnNum(stats.remainingParas)} পারা)`;
          remText.className = 'text-xs font-bold text-amber-600 dark:text-amber-400 font-mono';
        }
      }

      if (dailyText) {
        if (stats.isCompleted) {
          dailyText.textContent = 'খতম পূর্ণ হয়েছে';
        } else {
          dailyText.textContent = `${toBnNum(stats.dailyRequired)} পৃষ্ঠা/দিন (${toBnNum(stats.remainingDays)} দিন বাকি)`;
        }
      }
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
        const log = plannerState.logs[k];
        const isDone = log && (log.status === 'completed' || (log.totalDayPages && log.totalDayPages > 0));
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

    // TAB 2: Roadmap Generator (Dynamic Pace Adaptation)
    function renderPlannerRoadmapView() {
      const startDateInput = document.getElementById('cycleStartDateInput');
      if (startDateInput && !startDateInput.value) {
        startDateInput.value = formatDateKey(new Date());
      }
    }

    const generateCycleBtn = document.getElementById('generateCycleBtn');
    if (generateCycleBtn) {
      generateCycleBtn.addEventListener('click', () => {
        const targetDays = parseInt(document.getElementById('cycleTargetDaysSelect').value, 10) || 30;
        const startPara = parseInt(document.getElementById('cycleStartParaInput').value, 10) || 1;
        const startDateVal = document.getElementById('cycleStartDateInput').value;
        const startDate = startDateVal ? new Date(startDateVal) : new Date();

        plannerState.targetDays = targetDays;

        const stats = calculateKhatamStats();
        const pagesToDistribute = stats.remainingPages;
        const dailyTargetPages = Math.ceil(pagesToDistribute / targetDays);

        let d = new Date(startDate);

        for (let i = 0; i < targetDays; i++) {
          const dKey = formatDateKey(d);
          if (!plannerState.logs[dKey]) plannerState.logs[dKey] = { notes: [] };

          if (!plannerState.logs[dKey].totalDayPages) {
            plannerState.logs[dKey].generalTilawat = `টার্গেট: ${toBnNum(dailyTargetPages)} পৃষ্ঠা`;
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
          summaryText.textContent = `আলহামদুলিল্লাহ! আপনার লক্ষ্য অনুযায়ী অবশিষ্ট ${toBnNum(stats.remainingPages)} পৃষ্ঠা আগামী ${toBnNum(targetDays)} দিনে খতম করতে প্রতিদিন গড়ে ${toBnNum(dailyTargetPages)} পৃষ্ঠা (${toBnNum((dailyTargetPages/20).toFixed(1))} পারা) পড়তে হবে।`;
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
'''

# 1. Replace Tab 1
t1_start = content.find('<!-- TAB 1: Today\'s Focus -->')
t2_start = content.find('<!-- TAB 2: Roadmap & Plan -->')
t3_start = content.find('<!-- TAB 3: Quranic Diary & Notes -->')

if t1_start == -1 or t2_start == -1 or t3_start == -1:
    print('ERROR: tab markers not found!')
    exit(1)

content_updated = content[:t1_start] + tab1_replacement + '\n        ' + tab2_replacement + '\n        ' + content[t3_start:]

# 2. Replace JS
js_start = content_updated.find('// PLANNER STATE & DATA MANAGEMENT')
js_end = content_updated.find('// WUDU & PURITY GATEWAY SLIDER INTERACTION')

if js_start == -1 or js_end == -1:
    print('ERROR: js markers not found!')
    exit(1)

final_content = content_updated[:js_start] + planner_js.strip() + '\n\n    ' + content_updated[js_end:]

# Replace any em-dash just in case
final_content = final_content.replace('—', '-')

# Write to both docs/reader.html and landing/reader.html
with open('docs/reader.html', 'w', encoding='utf-8') as f:
    f.write(final_content)

with open('landing/reader.html', 'w', encoding='utf-8') as f:
    f.write(final_content)

print('SUCCESS: updated docs/reader.html and landing/reader.html with integer math engine')
