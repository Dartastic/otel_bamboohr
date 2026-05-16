// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_bamboohr_suppression.dart';

const _tracerName = 'dartastic_otel_libs_bamboohr';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class BamboohrResult {
  const BamboohrResult({
    this.itemCount,
    this.reportId,
    this.reportFormat,
    this.fieldsRequested,
    this.timeOffType,
    this.timeOffStatus,
    this.timeOffHours,
    this.employeeStatus,
    this.requestId,
    this.statusCode,
  });

  /// Items returned.
  final int? itemCount;

  /// Custom-report id when using report endpoints.
  final int? reportId;

  /// `xml` / `json` / `csv` / `pdf` / `xls` — affects payload size and
  /// caching.
  final String? reportFormat;

  /// Number of fields requested in `?fields=`. BambooHR is bandwidth-
  /// bound on big employee lists; this is the cost dim.
  final int? fieldsRequested;

  /// Vacation / Sick / Bereavement / FMLA / Personal / ...
  final String? timeOffType;

  /// `requested` / `approved` / `denied` / `superceded` / `canceled`.
  final String? timeOffStatus;

  /// Decimal hours requested.
  final double? timeOffHours;

  /// `Active` / `Inactive` / `Terminated`.
  final String? employeeStatus;

  /// `X-BambooHR-Trace-Id`.
  final String? requestId;

  final int? statusCode;
}

class BamboohrCallResult<T> {
  const BamboohrCallResult({required this.value, this.result});
  final T value;
  final BamboohrResult? result;
}

/// Wraps a BambooHR API call in a CLIENT span. [operation] is one of
/// `employees.directory`, `employees.get`, `employees.update`,
/// `employees.create`, `employees.tables.list`,
/// `employees.tables.get`, `reports.custom`, `reports.run`,
/// `time_off.requests.list`, `time_off.requests.create`,
/// `time_off.requests.update_status`, `time_off.policies.list`,
/// `time_off.balances`, `webhooks.list`, `webhooks.create`,
/// `meta.fields`.
Future<T> tracedBamboohr<T>({
  required String operation,
  required Future<BamboohrCallResult<T>> Function() invoke,
  String? subdomain,
}) async {
  if (bamboohrInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'bamboohr',
    'rpc.method': operation,
    'bamboohr.operation': operation,
  };
  if (subdomain != null) m['bamboohr.subdomain'] = subdomain;

  final span = _tracer().startSpan(
    'bamboohr $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTel.attributeInt(
          'bamboohr.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.reportId != null) {
        extras.add(OTel.attributeInt(
          'bamboohr.report.id',
          r.result!.reportId!,
        ));
      }
      if (r.result!.reportFormat != null) {
        extras.add(OTel.attributeString(
          'bamboohr.report.format',
          r.result!.reportFormat!,
        ));
      }
      if (r.result!.fieldsRequested != null) {
        extras.add(OTel.attributeInt(
          'bamboohr.fields_requested',
          r.result!.fieldsRequested!,
        ));
      }
      if (r.result!.timeOffType != null) {
        extras.add(OTel.attributeString(
          'bamboohr.time_off.type',
          r.result!.timeOffType!,
        ));
      }
      if (r.result!.timeOffStatus != null) {
        extras.add(OTel.attributeString(
          'bamboohr.time_off.status',
          r.result!.timeOffStatus!,
        ));
      }
      if (r.result!.timeOffHours != null) {
        extras.add(OTel.attributeDouble(
          'bamboohr.time_off.hours',
          r.result!.timeOffHours!,
        ));
      }
      if (r.result!.employeeStatus != null) {
        extras.add(OTel.attributeString(
          'bamboohr.employee.status',
          r.result!.employeeStatus!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTel.attributeString(
          'bamboohr.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'BambooHR HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
