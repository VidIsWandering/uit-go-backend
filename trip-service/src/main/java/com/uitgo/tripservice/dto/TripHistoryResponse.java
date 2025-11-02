package com.uitgo.tripservice.dto;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonProperty;

public class TripHistoryResponse {
    @JsonProperty("trips")
    private List<TripDetailResponse> trips;

    @JsonProperty("pagination")
    private PaginationInfo pagination;

    public TripHistoryResponse() {}

    public TripHistoryResponse(List<TripDetailResponse> trips, PaginationInfo pagination) {
        this.trips = trips;
        this.pagination = pagination;
    }

    public List<TripDetailResponse> getTrips() {
        return trips;
    }

    public void setTrips(List<TripDetailResponse> trips) {
        this.trips = trips;
    }

    public PaginationInfo getPagination() {
        return pagination;
    }

    public void setPagination(PaginationInfo pagination) {
        this.pagination = pagination;
    }

    public static class PaginationInfo {
        @JsonProperty("currentPage")
        private int currentPage;

        @JsonProperty("totalPages")
        private int totalPages;

        @JsonProperty("totalTrips")
        private long totalTrips;

        public PaginationInfo() {}

        public PaginationInfo(int currentPage, int totalPages, long totalTrips) {
            this.currentPage = currentPage;
            this.totalPages = totalPages;
            this.totalTrips = totalTrips;
        }

        public int getCurrentPage() { return currentPage; }
        public void setCurrentPage(int currentPage) { this.currentPage = currentPage; }

        public int getTotalPages() { return totalPages; }
        public void setTotalPages(int totalPages) { this.totalPages = totalPages; }

        public long getTotalTrips() { return totalTrips; }
        public void setTotalTrips(long totalTrips) { this.totalTrips = totalTrips; }
    }
}
