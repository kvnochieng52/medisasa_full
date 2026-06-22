<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class DpoPayService
{
    private ?string $companyToken;
    private ?string $apiUrl;
    private ?string $paymentUrl;
    private ?string $serviceType;

    public function __construct()
    {
        $this->companyToken = config('services.dpo.company_token');
        $this->apiUrl       = config('services.dpo.api_url');
        $this->paymentUrl   = config('services.dpo.payment_url');
        $this->serviceType  = config('services.dpo.service_type');
    }

    private function isConfigured(): bool
    {
        return $this->companyToken && $this->apiUrl && $this->paymentUrl && $this->serviceType;
    }

    public function createToken(array $data): array
    {
        if (!$this->isConfigured()) {
            Log::error('DPO Pay is not configured — missing env variables.');
            return ['success' => false, 'message' => 'Payment gateway is not configured on this server.'];
        }

        $xml = $this->buildCreateTokenXml($data);

        try {
            $response = Http::withHeaders(['Content-Type' => 'application/xml'])
                ->withBody($xml, 'application/xml')
                ->post($this->apiUrl);

            return $this->parseTokenResponse($response->body());
        } catch (\Exception $e) {
            Log::error('DPO createToken error: ' . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to connect to payment gateway'];
        }
    }

    public function verifyToken(string $transactionToken): array
    {
        if (!$this->isConfigured()) {
            return ['success' => false, 'status' => 'error', 'message' => 'Payment gateway is not configured on this server.'];
        }

        $xml = $this->buildVerifyTokenXml($transactionToken);

        try {
            $response = Http::withHeaders(['Content-Type' => 'application/xml'])
                ->withBody($xml, 'application/xml')
                ->post($this->apiUrl);

            return $this->parseVerifyResponse($response->body());
        } catch (\Exception $e) {
            Log::error('DPO verifyToken error: ' . $e->getMessage());
            return ['success' => false, 'status' => 'error', 'message' => 'Verification failed'];
        }
    }

    public function getPaymentUrl(string $transToken): string
    {
        return $this->paymentUrl . '?ID=' . $transToken;
    }

    private function buildCreateTokenXml(array $data): string
    {
        $serviceDate = date('Y-m-d H:i');

        return <<<XML
<?xml version="1.0" encoding="utf-8"?>
<API3G>
  <CompanyToken>{$this->companyToken}</CompanyToken>
  <Request>createToken</Request>
  <Transaction>
    <PaymentAmount>{$data['amount']}</PaymentAmount>
    <PaymentCurrency>KES</PaymentCurrency>
    <CompanyRef>{$data['company_ref']}</CompanyRef>
    <RedirectURL>{$data['redirect_url']}</RedirectURL>
    <BackURL>{$data['back_url']}</BackURL>
    <CompanyRefUnique>0</CompanyRefUnique>
    <PTL>30</PTL>
    <DefaultCountry>KE</DefaultCountry>
  </Transaction>
  <Services>
    <Service>
      <ServiceType>{$this->serviceType}</ServiceType>
      <ServiceDescription>{$data['description']}</ServiceDescription>
      <ServiceDate>{$serviceDate}</ServiceDate>
    </Service>
  </Services>
</API3G>
XML;
    }

    private function buildVerifyTokenXml(string $transactionToken): string
    {
        return <<<XML
<?xml version="1.0" encoding="utf-8"?>
<API3G>
  <CompanyToken>{$this->companyToken}</CompanyToken>
  <Request>verifyToken</Request>
  <TransactionToken>{$transactionToken}</TransactionToken>
</API3G>
XML;
    }

    private function parseTokenResponse(string $xml): array
    {
        Log::info('DPO createToken raw response: ' . substr($xml, 0, 500));

        // Detect HTML error page (CloudFront, nginx, etc.)
        if ($this->isHtmlResponse($xml)) {
            $httpCode = $this->extractHtmlErrorCode($xml);
            Log::error('DPO createToken returned HTML instead of XML. HTTP status hint: ' . $httpCode);
            return ['success' => false, 'message' => 'Payment gateway returned an unexpected response (' . $httpCode . '). Please try again or contact support.'];
        }

        libxml_use_internal_errors(true);
        try {
            $parsed = simplexml_load_string($xml);

            if ($parsed === false) {
                $errors = libxml_get_errors();
                libxml_clear_errors();
                $detail = !empty($errors) ? $errors[0]->message : 'unknown';
                Log::error('DPO createToken XML parse failed: ' . $detail);
                return ['success' => false, 'message' => 'Invalid response from payment gateway'];
            }

            $resultCode        = (string) $parsed->Result;
            $resultExplanation = (string) $parsed->ResultExplanation;

            if ($resultCode === '000') {
                return [
                    'success'     => true,
                    'trans_token' => (string) $parsed->TransToken,
                    'trans_ref'   => (string) ($parsed->TransRef ?? ''),
                ];
            }

            Log::warning('DPO createToken non-zero result: ' . $resultCode . ' — ' . $resultExplanation);
            return ['success' => false, 'message' => $resultExplanation ?: 'Token creation failed (code: ' . $resultCode . ')'];
        } catch (\Exception $e) {
            Log::error('DPO createToken exception: ' . $e->getMessage());
            return ['success' => false, 'message' => 'Failed to communicate with payment gateway'];
        } finally {
            libxml_use_internal_errors(false);
        }
    }

    private function parseVerifyResponse(string $xml): array
    {
        if ($this->isHtmlResponse($xml)) {
            Log::error('DPO verifyToken returned HTML instead of XML');
            return ['success' => false, 'status' => 'error', 'message' => 'Payment gateway returned an unexpected response'];
        }

        libxml_use_internal_errors(true);
        try {
            $parsed = simplexml_load_string($xml);

            if ($parsed === false) {
                libxml_clear_errors();
                return ['success' => false, 'status' => 'error', 'message' => 'Invalid response from payment gateway'];
            }

            $resultCode        = (string) $parsed->Result;
            $resultExplanation = (string) $parsed->ResultExplanation;

            // DPO result codes: 000=paid, 001=pending, 002=failed, 900=pending, 901=cancelled
            $statusMap = [
                '000' => 'paid',
                '001' => 'pending',
                '002' => 'failed',
                '900' => 'pending',
                '901' => 'cancelled',
                '902' => 'failed',
                '999' => 'failed',
            ];

            $status = $statusMap[$resultCode] ?? 'pending';

            return [
                'success'              => $resultCode === '000',
                'status'               => $status,
                'result_code'          => $resultCode,
                'message'              => $resultExplanation,
                'dpo_transaction_id'   => (string) ($parsed->TransactionApproval ?? ''),
                'transaction_amount'   => (string) ($parsed->TransactionAmount ?? ''),
                'transaction_currency' => (string) ($parsed->TransactionCurrency ?? ''),
                'customer_name'        => (string) ($parsed->CustomerName ?? ''),
                'customer_email'       => (string) ($parsed->CustomerEmail ?? ''),
            ];
        } catch (\Exception $e) {
            Log::error('DPO verifyToken exception: ' . $e->getMessage());
            return ['success' => false, 'status' => 'error', 'message' => 'Failed to verify payment'];
        } finally {
            libxml_use_internal_errors(false);
        }
    }

    private function isHtmlResponse(string $body): bool
    {
        $trimmed = ltrim($body);
        return stripos($trimmed, '<!DOCTYPE') === 0
            || stripos($trimmed, '<html') === 0
            || stripos($trimmed, '<HTML') === 0;
    }

    private function extractHtmlErrorCode(string $html): string
    {
        // Try to pull a status code like "403 ERROR" or "502 Bad Gateway" from the HTML title/heading
        if (preg_match('/<H1[^>]*>(\d{3}[^<]*)<\/H1>/i', $html, $m)) {
            return trim($m[1]);
        }
        if (preg_match('/<title[^>]*>(\d{3}[^<]*)<\/title>/i', $html, $m)) {
            return trim($m[1]);
        }
        return 'unknown error';
    }
}
