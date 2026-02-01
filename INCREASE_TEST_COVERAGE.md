# Using JaCoCo Reports to Prioritize Unit Test Efforts

## Overview

Rather than adding tests randomly, use the **JaCoCo code coverage report** to target high-impact areas systematically.

## Quick Start

Generate the coverage report:
```bash
./gradlew test jacocoTestReport
# Open: build/reports/jacoco/test/html/index.html
```

Or generate a comprehensive site with all reports:
```bash
./gradlew build site
# Open: build/site/index.html
```

## Finding Priority Packages

### Recommended Heuristics

1. **Sort by Coverage %** (ascending order) to find lowest coverage
2. **Filter for Missed Instructions > 500** (ignores trivial packages with little code)
3. **Manually skip abstract-heavy packages** (interfaces/abstract classes can't be directly tested)
4. **Focus on top 5 results** for actionable improvements

### Example Priority Analysis

```
Package                          Coverage%   Missed Instr   Priority
─────────────────────────────────────────────────────────────────────
net.sourceforge.plantuml.emoji      23%        2,847       🔴 HIGH
net.sourceforge.plantuml.svg        45%        1,234       🔴 HIGH  
net.sourceforge.plantuml.math       52%          987       🟡 MEDIUM
net.sourceforge.plantuml.core       78%          456       🟢 LOW
```

The `emoji` package shows **lowest coverage** (23%) AND **high missed instructions** (2,847) → **highest priority**.

## Understanding JaCoCo Metrics

| Metric | Meaning | Best For |
|--------|---------|----------|
| **Coverage %** | Percentage of instructions covered | Overall package health |
| **Missed Instructions** | Bytecode instructions not executed | Volume of untested code |
| **Missed Branches** | Conditional paths not taken (if/switch/ternary) | Logic complexity gaps |
| **Missed Lines** | Source lines not executed | Developer-friendly view |
| **Missed Methods** | Methods never called | API surface coverage |
| **Missed Classes** | Classes never instantiated | Dead code detection |
| **Cxty (Complexity)** | Cyclomatic complexity | Code complexity score |

## Avoiding Abstract Class Bias

Abstract classes and interfaces skew coverage metrics down because:
- Abstract methods have no implementation to test
- They're not directly instantiated  
- Coverage is only measured through subclass tests

### How to Handle This

**Focus on concrete implementations:**
- ✅ Look for `*Impl`, `*Service`, `*Manager`, `*Handler` patterns
- ✅ Prioritize packages with high **Cxty (Complexity)** - indicates complex logic needing coverage
- ❌ Skip utility packages dominated by interfaces

**Alternative metric combination:**
```
Priority Score = (Missed Instructions × Cxty) / Total Instructions
```
This weights complex concrete code higher than simple abstract scaffolding.

## Creating Targeted Issues

Instead of generic "Add more unit tests" issues, create focused, measurable tasks:

### Bad Example ❌
```
Title: Add more unit tests
Description: We need better test coverage
```

### Good Example ✅
```
Title: Improve test coverage for emoji package
Current Coverage: 23%
Missed Instructions: 2,847
Missed Branches: 156
Priority: HIGH
Target: Increase to 60%+ coverage

Focus Areas:
- BatikSvgHelper (0% coverage, 287 instructions)
- SvgDomParser (35% coverage, 1,234 instructions) 
- EmojiParser (78% coverage - already good)
```

## Benefits of This Approach

✅ **Measurable progress** - Clear before/after metrics  
✅ **Prevents duplication** - Easy to see what's already tested  
✅ **Efficient use of time** - Test high-impact code first  
✅ **Better code quality** - Complex logic gets proper coverage  
✅ **Visible improvements** - Coverage % increases are trackable

## Workflow Example

1. Generate JaCoCo report after each test run
2. Identify package with lowest coverage + high missed instructions
3. Create targeted issue with specific metrics
4. Write tests for that package
5. Re-run `./gradlew test jacocoTestReport`
6. Verify coverage increase
7. Move to next priority package

## Additional Resources

- [JaCoCo Documentation](https://www.jacoco.org/jacoco/trunk/doc/)
- PlantUML site generation: `./gradlew site` creates comprehensive reports
- Coverage reports location: `build/reports/jacoco/test/html/`
