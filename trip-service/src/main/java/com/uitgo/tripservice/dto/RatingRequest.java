package com.uitgo.tripservice.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public class RatingRequest {
    @JsonProperty("rating")
    private int rating;

    @JsonProperty("comment")
    private String comment;

    public RatingRequest() {}

    public int getRating() {
        return rating;
    }

    public void setRating(int rating) {
        this.rating = rating;
    }

    public String getComment() {
        return comment;
    }

    public void setComment(String comment) {
        this.comment = comment;
    }
}
