/*
 *    Copyright (C) 2013 Codenvy.
 *
 */
package com.codenvy.analytics.metrics;

import com.codenvy.analytics.metrics.ValueFromMapMetric.ValueType;

import java.io.IOException;

/**
 * @author <a href="mailto:abazko@codenvy.com">Anatoliy Bazko</a>
 */
public class ProjectCreatedTypeOthersPercentMetric extends ProjectsCreatedListMetric {

    ProjectCreatedTypeOthersPercentMetric() throws IOException {
        super(MetricType.PROJECT_TYPE_OTHERS_PERCENT, MetricFactory.createMetric(MetricType.PROJECTS_CREATED_LIST), new String[]{"default",
                "null", "eXo"}, ValueType.PERCENT);
    }
}
