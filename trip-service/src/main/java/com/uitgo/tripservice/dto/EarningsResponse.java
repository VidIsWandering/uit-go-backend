package com.uitgo.tripservice.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonProperty;

public class EarningsResponse {
    @JsonProperty("driverId")
    private UUID driverId;

    @JsonProperty("period")
    private String period;

    @JsonProperty("totalTrips")
    private int totalTrips;

    @JsonProperty("completedTrips")
    private int completedTrips;

    @JsonProperty("cancelledTrips")
    private int cancelledTrips;

    @JsonProperty("totalEarnings")
    private double totalEarnings;

    @JsonProperty("averageEarningsPerTrip")
    private double averageEarningsPerTrip;

    @JsonProperty("breakdown")
    private EarningsBreakdown breakdown;

    @JsonProperty("from")
    private OffsetDateTime from;

    @JsonProperty("to")
    private OffsetDateTime to;

    public EarningsResponse() {}

    // Getters and setters
    public UUID getDriverId() { return driverId; }
    public void setDriverId(UUID driverId) { this.driverId = driverId; }

    public String getPeriod() { return period; }
    public void setPeriod(String period) { this.period = period; }

    public int getTotalTrips() { return totalTrips; }
    public void setTotalTrips(int totalTrips) { this.totalTrips = totalTrips; }

    public int getCompletedTrips() { return completedTrips; }
    public void setCompletedTrips(int completedTrips) { this.completedTrips = completedTrips; }

    public int getCancelledTrips() { return cancelledTrips; }
    public void setCancelledTrips(int cancelledTrips) { this.cancelledTrips = cancelledTrips; }

    public double getTotalEarnings() { return totalEarnings; }
    public void setTotalEarnings(double totalEarnings) { this.totalEarnings = totalEarnings; }

    public double getAverageEarningsPerTrip() { return averageEarningsPerTrip; }
    public void setAverageEarningsPerTrip(double averageEarningsPerTrip) { this.averageEarningsPerTrip = averageEarningsPerTrip; }

    public EarningsBreakdown getBreakdown() { return breakdown; }
    public void setBreakdown(EarningsBreakdown breakdown) { this.breakdown = breakdown; }

    public OffsetDateTime getFrom() { return from; }
    public void setFrom(OffsetDateTime from) { this.from = from; }

    public OffsetDateTime getTo() { return to; }
    public void setTo(OffsetDateTime to) { this.to = to; }

    public static class EarningsBreakdown {
        @JsonProperty("tripFees")
        private double tripFees;

        @JsonProperty("bonuses")
        private double bonuses;

        @JsonProperty("tips")
        private double tips;

        @JsonProperty("commission")
        private double commission;

        @JsonProperty("netEarnings")
        private double netEarnings;

        public EarningsBreakdown() {}

        public double getTripFees() { return tripFees; }
        public void setTripFees(double tripFees) { this.tripFees = tripFees; }

        public double getBonuses() { return bonuses; }
        public void setBonuses(double bonuses) { this.bonuses = bonuses; }

        public double getTips() { return tips; }
        public void setTips(double tips) { this.tips = tips; }

        public double getCommission() { return commission; }
        public void setCommission(double commission) { this.commission = commission; }

        public double getNetEarnings() { return netEarnings; }
        public void setNetEarnings(double netEarnings) { this.netEarnings = netEarnings; }
    }
}
