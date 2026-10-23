// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_bamboohr/otel_bamboohr.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_bamboohr-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('time_off.create records type + hours', () async {
    await tracedBamboohr<String>(
      operation: 'time_off.requests.create',
      subdomain: 'acme',
      invoke: () async => const BamboohrCallResult(
        value: 'ok',
        result: BamboohrResult(
          timeOffType: 'Vacation',
          timeOffStatus: 'requested',
          timeOffHours: 16.0,
          employeeStatus: 'Active',
          statusCode: 201,
        ),
      ),
    );
    final a = attrsOf(
      spans.findSpanByName('bamboohr time_off.requests.create')!,
    );
    expect(a['bamboohr.subdomain'], 'acme');
    expect(a['bamboohr.time_off.type'], 'Vacation');
    expect(a['bamboohr.time_off.hours'], 16.0);
  });

  test('report run records format + fields', () async {
    await tracedBamboohr<String>(
      operation: 'reports.custom',
      invoke: () async => const BamboohrCallResult(
        value: 'ok',
        result: BamboohrResult(
          reportId: 42,
          reportFormat: 'csv',
          fieldsRequested: 28,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('bamboohr reports.custom')!);
    expect(a['bamboohr.report.format'], 'csv');
    expect(a['bamboohr.fields_requested'], 28);
  });

  test('suppression skips spans', () async {
    await runWithoutBamboohrInstrumentationAsync(() async {
      await tracedBamboohr<String>(
        operation: 'employees.directory',
        invoke: () async => const BamboohrCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('bamboohr '), isEmpty);
  });
}
