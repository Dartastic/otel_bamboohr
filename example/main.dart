// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_bamboohr/otel_bamboohr.dart';

/// Traces BambooHR calls with OpenTelemetry.
///
/// `otel_bamboohr` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each BambooHR call in
/// [tracedBamboohr]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'bamboohr-example');

  // Wraps a BambooHR API call in a CLIENT span.
  final bamboohrId = await tracedBamboohr<String>(
    operation: 'employees.create',
    subdomain: 'example',
    invoke: () async {
      // Make the BambooHR call here, then report what it returned.
      const id = 'bamboohr_8f3a2c';
      return const BamboohrCallResult(
          value: id,
          result: BamboohrResult(
              itemCount: 3,
              reportId: 443,
              reportFormat: 'xml',
              fieldsRequested: 1,
              timeOffType: 'standard',
              timeOffStatus: 'requested',
              timeOffHours: 0.5,
              employeeStatus: 'Active',
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedBamboohr employees.create returned $bamboohrId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutBamboohrInstrumentationAsync.
  await runWithoutBamboohrInstrumentationAsync(
    () => tracedBamboohr<String>(
      operation: 'employees.create',
      subdomain: 'example',
      invoke: () async {
        const id = 'bamboohr_8f3a2c';
        return const BamboohrCallResult(
            value: id,
            result: BamboohrResult(
                itemCount: 3,
                reportId: 443,
                reportFormat: 'xml',
                fieldsRequested: 1,
                timeOffType: 'standard',
                timeOffStatus: 'requested',
                timeOffHours: 0.5,
                employeeStatus: 'Active',
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
