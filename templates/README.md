# Finance & Accounting Equiz Course Package

## Overview

This package contains approximately **700 questions** across **69 quizzes** organized into four courses for use with the SylSpace equiz system.

However, the questions here --- other than options and corpfinintro --- have not been vetted.  If you have suggestions for changes, please let me know (ivo.welch@gmail.com).


## Courses Included

### 1. Options Pricing (18 quizzes, ~180 questions)
1. Option Payoffs and Basics
2. Put-Call Parity
3. Binomial Model - One Period
4. Binomial Model - Two Period
5. Black-Scholes Model
6. Option Greeks: Delta and Gamma
7. Option Greeks: Theta, Vega, Rho
8. Option Strategies: Spreads
9. Straddles and Strangles
10. Butterflies and Condors
11. Forwards and Futures Pricing
12. American Options and Early Exercise
13. Implied Volatility and Volatility Surface
14. Delta Hedging and Risk Management
15. Exotic Options Introduction
16. Options on Indices and Futures
17. Real Options Valuation
18. Option Portfolio Management

### 2. Fixed Income (16 quizzes, ~160 questions)
1. Bond Pricing Basics
2. Yield to Maturity
3. Duration
4. Convexity
5. Spot Rates and Term Structure
6. Forward Rates
7. Interest Rate Risk
8. Credit Risk and Spreads
9. Interest Rate Swaps
10. Bond Futures
11. Mortgage-Backed Securities
12. Money Markets and Short-Term Instruments
13. Callable and Putable Bonds
14. Fixed Income Portfolio Management
15. Structured Products
16. Immunization and Liability Matching

### 3. Introductory Accounting (18 quizzes, ~180 questions)
1. The Accounting Equation and Balance Sheet
2. Income Statement
3. Cash Flow Statement
4. Journal Entries and Debits/Credits
5. Accounts Receivable and Bad Debt
6. Inventory
7. Depreciation and Fixed Assets
8. Financial Ratios: Liquidity and Solvency
9. Financial Ratios: Profitability and Returns
10. Liabilities and Bonds Payable
11. Shareholders' Equity
12. Revenue Recognition and Accrual Accounting
13. Earnings Per Share
14. Working Capital Management
15. Deferred Taxes
16. Financial Statement Analysis
17. Consolidation and Investments
18. International Accounting and Currency

### 4. Valuation (17 quizzes, ~180 questions)
1. Time Value of Money
2. Cost of Capital
3. DCF Valuation: Free Cash Flow
4. Comparable Company Analysis
5. Precedent Transactions Analysis
6. LBO Fundamentals
7. Dividend Discount Models
8. Enterprise Value Bridge
9. Residual Income and EVA
10. Merger Accretion and Dilution
11. Sum of the Parts Valuation
12. Sensitivity Analysis
13. Industry-Specific Multiples
14. Sensitivity and Scenario Analysis
15. Adjusted Present Value (APV)
16. Private Company Valuation

## Features

- All questions use randomized numerical parameters for unlimited practice
- Detailed worked solutions provided for each question
- Questions progress from fundamental concepts to advanced applications
- Covers CFA, FRM, and MBA-level material

## Installation

Copy the .equiz files to your SylSpace templates/equiz directory:

```bash
unzip equiz-courses.zip
cp -r options fixed-income accounting valuation /path/to/sylspace/templates/equiz/
```

## Notes

- Questions use standard equiz syntax with :I: for randomized inputs
- Most questions have 10-second default time limits
- Numerical precision is typically 0.01 or better
- Some questions use helper functions like BlackScholes(), CumNorm(), etc.
