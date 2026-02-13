#!/bin/bash

# Script to create Phase 5b issues in GitHub

REPO="gromeroalfonso/context.ai"

echo "Creating Phase 5b sub-issues..."

# Issue 5b.1
echo "Creating 5b.1..."
gh issue create --repo $REPO \
  --title "5b.1: Update color scheme to teal and import prototype theme variables" \
  --label "enhancement" \
  --body "## 🎯 Objective
Update global CSS variables to match prototype's teal color scheme.

## 📝 Files: \`src/app/globals.css\`

## 🎨 Changes: Update CSS variables to teal (#2D9D8E) and dark sidebar theme

## ✅ Criteria
- [ ] Teal primary color
- [ ] Dark sidebar theme  
- [ ] WCAG AA contrast

**Priority:** 🔴 High | **Time:** 30 min | **Parent:** #98"

sleep 3

# Issue 5b.2
echo "Creating 5b.2..."
gh issue create --repo $REPO \
  --title "5b.2: Implement collapsible sidebar navigation with shadcn/ui" \
  --label "enhancement" \
  --body "## 🎯 Objective
Implement sidebar navigation component based on shadcn/ui.

## 📝 Files to Create
- \`src/components/ui/sidebar.tsx\`
- \`src/components/dashboard/AppSidebar.tsx\`

## 🔑 Features
- Brain icon logo + Context.ai branding
- Navigation: Overview, AI Chat, Knowledge
- Auth0 user avatar + logout
- Collapsible (desktop) / Drawer (mobile)

## ✅ Criteria
- [ ] Sidebar renders
- [ ] Navigation works with locale
- [ ] Auth0 integration
- [ ] Responsive

**Priority:** 🔴 High | **Time:** 1-2 hrs | **Depends:** #99 | **Parent:** #98"

sleep 3

# Issue 5b.3
echo "Creating 5b.3..."
gh issue create --repo $REPO \
  --title "5b.3: Refactor protected layout to use sidebar instead of navbar" \
  --label "enhancement" \
  --body "## 🎯 Objective
Update protected routes layout to use sidebar instead of top navbar.

## 📝 Files: \`src/app/[locale]/(protected)/layout.tsx\`

## 🏗️ Change
Replace top navbar with SidebarProvider + AppSidebar + SidebarInset layout

## ✅ Criteria
- [ ] Sidebar layout implemented
- [ ] Header with trigger + language selector
- [ ] Content scrolls independently
- [ ] Responsive

**Priority:** 🔴 High | **Time:** 1 hr | **Depends:** #100 | **Parent:** #98"

sleep 3

# Issue 5b.4
echo "Creating 5b.4..."
gh issue create --repo $REPO \
  --title "5b.4: Build complete landing page with hero, features, and CTA sections" \
  --label "enhancement" \
  --body "## 🎯 Objective
Create professional landing page for unauthenticated users.

## 📝 Components to Create
- LandingNavbar, HeroSection, FeaturesSection
- HowItWorksSection, UseCasesSection, CtaFooter

## 🔄 Adaptations
Use next-intl (\`useTranslations('landing')\`) instead of custom dictionaries

## ✅ Criteria
- [ ] All 6 components created
- [ ] Translations added (en + es)
- [ ] next-intl integration
- [ ] Responsive design

**Priority:** 🟡 Medium | **Time:** 3-4 hrs | **Parent:** #98"

sleep 3

# Issue 5b.5
echo "Creating 5b.5..."
gh issue create --repo $REPO \
  --title "5b.5: Replace MessageSquare logo with Brain icon across application" \
  --label "enhancement" \
  --body "## 🎯 Objective
Update all MessageSquare logos to Brain icon for consistent branding.

## 🔄 Change
\`\`\`typescript
// Before: import { MessageSquare } from 'lucide-react';
// After: import { Brain } from 'lucide-react';
\`\`\`

## 🎨 Branding
- Icon: Brain (lucide-react)
- Name: Context.ai
- Color: Teal

## ✅ Criteria
- [ ] Brain icon in all navigation
- [ ] No MessageSquare imports remain

**Priority:** 🟢 Low | **Time:** 30 min | **Parent:** #98"

sleep 3

# Issue 5b.6
echo "Creating 5b.6..."
gh issue create --repo $REPO \
  --title "5b.6: Update chat and dashboard pages to work with sidebar layout" \
  --label "enhancement" \
  --body "## 🎯 Objective
Adapt chat and dashboard pages for sidebar layout.

## 📝 Files
- Modify: \`src/app/[locale]/(protected)/chat/page.tsx\`
- Create: \`src/app/[locale]/(protected)/dashboard/page.tsx\`

## 🎨 Changes
- Chat: Adjust for sidebar (remove hardcoded heights)
- Dashboard: Create overview with stats cards

## ✅ Criteria
- [ ] Chat works with sidebar
- [ ] Dashboard page created
- [ ] Both responsive
- [ ] Translations added

**Priority:** 🟡 Medium | **Time:** 1-2 hrs | **Depends:** #101 | **Parent:** #98"

echo "✅ All Phase 5b issues created!"

