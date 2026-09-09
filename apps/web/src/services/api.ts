const BASE_URL = "http://localhost:5000/api";

async function request(
    path: string,
    options: RequestInit = {}
) {
    const token = localStorage.getItem("token");

    const headers: Record<string, string> = {
        "Content-Type": "application/json",
        ...((options.headers as Record<string, string>) || {}),
    };

    if (token) {
        headers["Authorization"] = `Bearer ${token}`;
    }

    const response = await fetch(`${BASE_URL}${path}`, {
        ...options,
        headers,
    });

    if (!response.ok) {
        let errorMessage = `Request failed: ${response.status}`;
        try {
            const errJson = await response.json();
            errorMessage = errJson.message || errJson.error || errorMessage;
        } catch {
            const errText = await response.text().catch(() => "");
            if (errText) errorMessage = errText;
        }
        if (response.status === 401) {
            // Unauthorized - token might be expired
            localStorage.removeItem("token");
            localStorage.removeItem("user");
        }
        throw new Error(errorMessage);
    }

    if (response.status === 204) {
        return null;
    }

    const json = await response.json();
    return json.data !== undefined ? json.data : json;
}

export const api = {
    get: (path: string) =>
        request(path, {
            method: "GET",
        }),

    post: (path: string, data: unknown) =>
        request(path, {
            method: "POST",
            body: JSON.stringify(data),
        }),

    put: (path: string, data: unknown) =>
        request(path, {
            method: "PUT",
            body: JSON.stringify(data),
        }),

    patch: (path: string, data: unknown) =>
        request(path, {
            method: "PATCH",
            body: JSON.stringify(data),
        }),

    delete: (path: string) =>
        request(path, {
            method: "DELETE",
        }),
};