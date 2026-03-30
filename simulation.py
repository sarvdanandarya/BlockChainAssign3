import random
import matplotlib.pyplot as plt

# -----------------------------
# Initial Setup
# -----------------------------
NUM_LPS = 5
NUM_TRADERS = 8
N = 80  # number of transactions

# Pool reserves
reserveA = 10000
reserveB = 10000

# Users
users = [{"A": 1000, "B": 1000, "LP": 0} for _ in range(NUM_LPS + NUM_TRADERS)]

# Metrics tracking
tvl_list = []
price_list = []
slippage_list = []
volume_list = []
fee_list = []

total_fees = 0

# -----------------------------
# Simulation
# -----------------------------
for t in range(N):

    user = random.choice(users)
    action = random.choice(["swap", "add", "remove"])

    # ---------------- SWAP ----------------
    if action == "swap" and user["A"] > 0:

        max_swap = min(user["A"], 0.1 * reserveA)
        if max_swap <= 0:
            continue

        amountA = random.uniform(1, max_swap)

        # Expected price
        expected_price = reserveB / reserveA

        # Fee
        amountA_with_fee = amountA * 0.997

        # AMM calculation
        newA = reserveA + amountA_with_fee
        newB = (reserveA * reserveB) / newA

        amountB = reserveB - newB

        # Actual price
        actual_price = amountB / amountA

        # Slippage
        slippage = ((actual_price - expected_price) / expected_price) * 100
        slippage_list.append(slippage)

        # Update reserves
        reserveA += amountA_with_fee
        reserveB -= amountB

        # Update user
        user["A"] -= amountA
        user["B"] += amountB

        # Metrics
        volume_list.append(amountA)
        fee = amountA * 0.003
        total_fees += fee
        fee_list.append(total_fees)

    # ---------------- ADD LIQUIDITY ----------------
    elif action == "add" and user["A"] > 0 and user["B"] > 0:

        amountA = random.uniform(1, user["A"])
        amountB = amountA * (reserveB / reserveA)

        if user["B"] < amountB:
            continue

        reserveA += amountA
        reserveB += amountB

        user["A"] -= amountA
        user["B"] -= amountB
        user["LP"] += amountA  # simplified share

    # ---------------- REMOVE LIQUIDITY ----------------
    elif action == "remove" and user["LP"] > 0:

        share = random.uniform(0, user["LP"])

        amountA = (share / reserveA) * reserveA
        amountB = (share / reserveB) * reserveB

        reserveA -= amountA
        reserveB -= amountB

        user["A"] += amountA
        user["B"] += amountB
        user["LP"] -= share

    # ---------------- TRACK METRICS ----------------
    tvl = reserveA + reserveB
    price = reserveB / reserveA

    tvl_list.append(tvl)
    price_list.append(price)

# -----------------------------
# PLOTS
# -----------------------------
plt.figure(figsize=(12,8))

plt.subplot(2,2,1)
plt.plot(tvl_list)
plt.title("TVL")

plt.subplot(2,2,2)
plt.plot(price_list)
plt.title("Spot Price")

plt.subplot(2,2,3)
plt.plot(slippage_list)
plt.title("Slippage")

plt.subplot(2,2,4)
plt.plot(fee_list)
plt.title("Fees Collected")

plt.tight_layout()
plt.show()